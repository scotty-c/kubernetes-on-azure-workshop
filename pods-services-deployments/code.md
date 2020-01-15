# Pods, services and deployments

![slide 1](../slides/pods-services-deployments/Slide1.jpg)
![slide 2](../slides/pods-services-deployments/Slide2.jpg)
![slide 3](../slides/pods-services-deployments/Slide3.jpg)
![slide 4](../slides/pods-services-deployments/Slide4.jpg)
![slide 5](../slides/pods-services-deployments/Slide5.jpg)
![slide 6](../slides/pods-services-deployments/Slide6.jpg)
![slide 7](../slides/pods-services-deployments/Slide7.jpg)
![slide 8](../slides/pods-services-deployments/Slide8.jpg)
![slide 9](../slides/pods-services-deployments/Slide9.jpg)
![slide 10](../slides/pods-services-deployments/Slide10.jpg)
![slide 11](../slides/pods-services-deployments/Slide11.jpg)

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

## Now check our deployment

```
kubectl get deployments
kubectl get pods
kubectl get services
```

![slide 14](../slides/pods-services-deployments/Slide14.jpg)
![slide 15](../slides/pods-services-deployments/Slide15.jpg)

## Expose our service
`kubectl expose deployment webapp-deployment --type=LoadBalancer`  
`kubectl get service`


`kubectl get service` will give you the public ip address for the application. It will then be available  

![slide 17](../slides/pods-services-deployments/Slide17.jpg)

Now we move onto the next module [here](../rbac-roles-service-accounts/code.md)