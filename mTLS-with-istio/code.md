# mTLS with istio

## Create our namespace
`kubectl create namespace istio-app`
`kubectl label namespace istio-app istio-injection=enabled`

## Enbale mTLS across our namespace
```
cat <<EOF | istioctl create -f -
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: default
  namespace: istio-app
spec:
  peers:
  - mtls:
EOF
```

## Create a destination rule
```
cat <<EOF | istioctl create -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: default
  namespace: istio-app
spec:
  host: "*"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

## Deploy our application
`kubectl create -n istio-app -f istio-1.0.4/samples/bookinfo/platform/kube/bookinfo.yaml`

## Create our virtual service
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

## Create our gateway 
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
`kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')`

## Check out your mTLS status
`istioctl authn tls-check | grep .istio-app.svc.cluster.local`

```
export POD_NAME=$(kubectl get pods --namespace=istio-app | grep details | cut -d' ' -f1)
kubectl exec -n istio-app -it $POD_NAME -c istio-proxy /bin/bash
```

## Hit a service internally 
`curl -k -v http://details:9080/details/0` 

## Let's capture traffic with tcpdump
```
IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
sudo tcpdump -vvv -A -i eth0 '((dst port 9080) and (net $IP))'
```

## From another terminal
```
curl -o /dev/null -s -w "%{http_code}\n" http://$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/productpage
```
