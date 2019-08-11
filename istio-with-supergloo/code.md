# Istio with Supergloo

In another [module](../advance-application-routing-with-istio/code.md) we look at installing manually. In this module we are going to look at doing the same with [Supergloo](https://supergloo.solo.io/) Now you may ask why?  
Supergloo gives us a really nice ux to work with Istio. 

## Installing istio
To install istio with Supergloo you issue the following command  
```
supergloo install istio --name istio --installation-namespace istio-system --mtls=true --auto-inject=true --ingress=true
```  
You will notice we are going to set the flags to enable mTLS and auto injection.  
After you issue the command you will get the following output
```
+---------+------------+---------+---------------------------+
| INSTALL |    TYPE    | STATUS  |          DETAILS          |
+---------+------------+---------+---------------------------+
| istio   | Istio Mesh | Pending | enabled: true             |
|         |            |         | version: 1.0.6            |
|         |            |         | namespace: istio-system   |
|         |            |         | mtls enabled: true        |
|         |            |         | auto inject enabled: true |
|         |            |         | grafana enabled: false    |
|         |            |         | prometheus enabled: false |
|         |            |         | jaeger enabled: false     |
|         |            |         | ingress enabled: true     |
|         |            |         | egress enabled: false     |
+---------+------------+---------+---------------------------+
```

## Testing out mTLS
We will now deploy a new namespace with and allow istio to auto inject the envoy proxy.  
```
kubectl create namespace istio-app
kubectl label namespace istio-app istio-injection=enabled
```

Next we will deploy our demo application in our new namespace  
```
kubectl --namespace istio-app apply --filename \
    https://raw.githubusercontent.com/solo-io/supergloo/master/test/e2e/files/bookinfo.yaml
```  

Then we will deploy our virtual service fot routing
```
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
  namespace: istio-app
spec:
  gateways:
  - bookinfo-gateway
  hosts:
  - '*'
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080
EOF
```

Then bind the routes to our istio gateway
```
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
  namespace: istio-app
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
EOF
```

You can now get the public ip of the ingress gateway
```
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then to check you application open a browser and use the public ip listed in the command above and add `/productpage` for example my ip is `40.121.151.134` so in the browser I would use `http://40.121.151.134/productpage`

Now we have our application we can test out the mTLS communication. We will do that with [tcpdump](https://www.tcpdump.org/manpages/tcpdump.1.html) via the envoy sidecar. To get shell access to that pod we will issue the following      
```
export POD_NAME=$(kubectl get pods --namespace=istio-app | grep details | cut -d' ' -f1)
kubectl exec -n istio-app -it $POD_NAME -c istio-proxy /bin/bash
```

From inside that terminal we will try to hit a service internally 
`curl -k -v http://details:9080/details/0`

We should get a connection refused  
```
*   Trying 10.0.70.13...
* Connected to details (10.0.70.13) port 9080 (#0)
> GET /details/0 HTTP/1.1
> Host: details:9080
> User-Agent: curl/7.47.0
> Accept: */*
> 
* Recv failure: Connection reset by peer
* Closing connection 0
curl: (56) Recv failure: Connection reset by peer
```

Now lets use tcp dump  
```
IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
echo $IP
sudo tcpdump -vvv -A -i eth0 '((dst port 9080) and (net <Use ip from above>))'
```
Make sure to replace `<Use ip from above>` with the output of `echo $IP`  

Now open a new terminal not inside the proxy and hit the public end point
```
curl -o /dev/null -s -w "%{http_code}\n" http://$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/productpage
```

And tcpdump will show you the traffic is encrypted 
```
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
01:44:26.321505 IP (tos 0x0, ttl 62, id 29808, offset 0, flags [DF], proto TCP (6), length 985)
    10-244-2-10.productpage.istio-app.svc.cluster.local.56608 > details-v1-68b96b8855-8gz6d.9080: Flags [P.], cksum 0xcb35 (correct), seq 2023992897:2023993830, ack 3234861546, win 309, options [nop,nop,TS val 921785932 ecr 2584296252], length 933
E...tp@.>...
..

..	. #xx..A.......5.5.....
6.VL.	;<..............Z...n.L..;7c.......D+M+......z![..b......o.O.ST.8...+>.h....8.V..;....n.jB..FB	t.
.|.../.2...D.y<....s......y.D:.<..,.Q.6..<T7W[...._..HO.
........*rm"O......^u....3....w.....f.............n..0............i............!/.}(].Y.y^f....f.... .0..J..g..h..K.b.o...F..F.^../.%..N..@.x..L....?....f..y..tr..[.K...X.Z.F.........vK0...Jp.@..6.li.wZMT.. 9K.............._..."'Q........:...2{....F?i1M.#<05....I. 
Cy.[........B.i{bi.,/..-..$J..`..%.2..?,.g.......-......o...;...... .^....;.`.}.tL.-...4...$.T..3..8..sR.?1...\Kd.B...Is8_.W...j-h....|.h.T...W..	...X.[..x..#|...~t.....x.......8....B..Yo.....K.....#E....p|.H....aUsw......\.!.=;....!...b..<...M..(i9......../......f..5.t8f#}...r{..S...4.P.P...q../.........=.!!....r...
...D./>..^S....u.(.x_N..j..R...;M........hf.!..f..Z@...}.;....`.....(.....[....+.b...U....	.....IpB.ZU.	O:..A...`..D.:mB..c.I....U.~..
.....\.B..R.z.BT.......G........G.*w|.B	Me...<.7..;.........
01:44:26.370014 IP (tos 0x0, ttl 62, id 29809, offset 0, flags [DF], proto TCP (6), length 52)
    10-244-2-10.productpage.istio-app.svc.cluster.local.56608 > details-v1-68b96b8855-8gz6d.9080: Flags [.], cksum 0x74ec (correct), seq 933, ack 366, win 329, options [nop,nop,TS val 921785981 ecr 2584854722], length 0
E..4tq@.>..X
..

..	. #xx......W...It......
6.V}....
01:44:51.719390 IP (tos 0x0, ttl 64, id 30975, offset 0, flags [DF], proto TCP (6), length 60)
    10.244.1.3.52284 > details-v1-68b96b8855-8gz6d.9080: Flags [S], cksum 0x1822 (incorrect -> 0x0b29), seq 590050211, win 29200, options [mss 1460,sackOK,TS val 1051389349 ecr 0,nop,wscale 7], length 0
E..<x.@.@...
...
..	.<#x#+s.......r..".........
>...........
01:44:51.719440 IP (tos 0x0, ttl 64, id 30976, offset 0, flags [DF], proto TCP (6), length 52)
    10.244.1.3.52284 > details-v1-68b96b8855-8gz6d.9080: Flags [.], cksum 0x181a (incorrect -> 0xaf81), seq 590050212, ack 3111167789, win 229, options [nop,nop,TS val 1051389349 ecr 2269647784], length 0
E..4y.@.@...
...
..	.<#x#+s..p.-...........
>....H..
01:44:51.720032 IP (tos 0x0, ttl 64, id 30977, offset 0, flags [DF], proto TCP (6), length 76)
    10.244.1.3.52284 > details-v1-68b96b8855-8gz6d.9080: Flags [P.], cksum 0x1832 (incorrect -> 0x6a52), seq 0:24, ack 1, win 229, options [nop,nop,TS val 1051389349 ecr 2269647784], length 24
E..Ly.@.@...
...
..	.<#x#+s..p.-.....2.....
>....H..PRI * HTTP/2.0

SM


01:44:51.720164 IP (tos 0x0, ttl 64, id 30978, offset 0, flags [DF], proto TCP (6), length 61)
    10.244.1.3.52284 > details-v1-68b96b8855-8gz6d.9080: Flags [P.], cksum 0x1823 (incorrect -> 0xaf54), seq 24:33, ack 1, win 229, options [nop,nop,TS val 1051389349 ecr 2269647784], length 9
E..=y.@.@...
...
..	.<#x#+s..p.-.....#.....
>....H...........
01:44:51.720191 IP (tos 0x0, ttl 64, id 30979, offset 0, flags [DF], proto TCP (6), length 52)
    10.244.1.3.52284 > details-v1-68b96b8855-8gz6d.9080: Flags [.], cksum 0x181a (incorrect -> 0xaf59), seq 33, ack 8, win 229, options [nop,nop,TS val 1051389349 ecr 2269647784], length 0
E..4y.@.@...
...
..	.<#x#+s..p.4...........
>....H..
01:46:14.077221 IP (tos 0x0, ttl 64, id 26455, offset 0, flags [DF], proto TCP (6), length 60)
    10.244.1.3.52922 > details-v1-68b96b8855-8gz6d.9080: Flags [S], cksum 0x1822 (incorrect -> 0xc5ac), seq 1534606494, win 29200, options [mss 1460,sackOK,TS val 1051471706 ecr 0,nop,wscale 7], length 0
E..<gW@.@..q
...
..	..#x[x<.......r..".........
>./Z........
01:46:14.077300 IP (tos 0x0, ttl 64, id 26456, offset 0, flags [DF], proto TCP (6), length 52)
    10.244.1.3.52922 > details-v1-68b96b8855-8gz6d.9080: Flags [.], cksum 0x181a (incorrect -> 0xfc83), seq 1534606495, ack 1446327858, win 229, options [nop,nop,TS val 1051471707 ecr 2269730142], length 0
E..4gX@.@..x
...
..	..#x[x<.V562...........
>./[.IU^
01:46:14.078164 IP (tos 0x0, ttl 64, id 26457, offset 0, flags [DF], proto TCP (6), length 76)
    10.244.1.3.52922 > details-v1-68b96b8855-8gz6d.9080: Flags [P.], cksum 0x1832 (incorrect -> 0xb754), seq 0:24, ack 1, win 229, options [nop,nop,TS val 1051471707 ecr 2269730142], length 24
E..LgY@.@.._
...
..	..#x[x<.V562.....2.....
>./[.IU^PRI * HTTP/2.0

SM


01:46:14.078204 IP (tos 0x0, ttl 64, id 26458, offset 0, flags [DF], proto TCP (6), length 61)
    10.244.1.3.52922 > details-v1-68b96b8855-8gz6d.9080: Flags [P.], cksum 0x1823 (incorrect -> 0xfc56), seq 24:33, ack 1, win 229, options [nop,nop,TS val 1051471707 ecr 2269730142], length 9
E..=gZ@.@..m
...
..	..#x[x<.V562.....#.....
>./[.IU^.........
01:46:14.078288 IP (tos 0x0, ttl 64, id 26459, offset 0, flags [DF], proto TCP (6), length 52)
    10.244.1.3.52922 > details-v1-68b96b8855-8gz6d.9080: Flags [.], cksum 0x181a (incorrect -> 0xfc59), seq 33, ack 8, win 229, options [nop,nop,TS val 1051471708 ecr 2269730143], length 0
E..4g[@.@..u
...
..	..#x[x<.V569...........
>./\.IU_

^C
12 packets captured
12 packets received by filter
0 packets dropped by kernel
```

## Clean up
Now let's cleanup our environment.

Delete our test app
```
kubectl --namespace istio-app delete --filename \
    https://raw.githubusercontent.com/solo-io/supergloo/master/test/e2e/files/bookinfo.yaml
```

and delete istio 
```
supergloo uninstall --name istio
```