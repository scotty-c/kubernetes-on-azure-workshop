# Writing our own chart

## Writing our first chart 

`helm create mychart`

`helm install --dry-run --debug ./mychart`

`helm install --name example ./mychart --set service.type=LoadBalancer`

`kubectl get svc --namespace default example-mychart -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
