# Pods, services and deployments

In this module we are going to deploy our first deployment, below is the code to do so.

## Our Deployment
```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: webapp-deployment
spec:
  selector:
    matchLabels:
      app: webapp
  replicas: 3
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: scottyc/webapp:latest
        ports:
        - containerPort: 3000
          hostPort: 3000
EOF
```

Now to expose the service so you can hit the application from the outside world.

## Expose our service
`kubectl expose deployment webapp-deployment --type=LoadBalancer`  
`kubectl get service`


`kubectl get service` will give you the public ip address for the application. It will then be available  
at `http://<Your public ip>:3000` 
