# Writing our own chart

## Writing our first chart 

In this module we are going to write our own helm chart.  

Let's create the chart  
`helm create mychart`

Helm will now have created a working nginx chart for us  

We can actually test this chart with a dry run to see what it is going to deploy
`helm install --dry-run --debug ./mychart`


We can than deploy the chart  
`helm install --name example ./mychart --set service.type=LoadBalancer`


Now we can check the nginx install in our browser, to get the public ip  
`kubectl get svc --namespace default example-mychart -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`


Some homework take the chart we have created today and then use it as a template to deploy your own application.  
This is how I learnt to write custom Helm charts and I found it really rewarding  