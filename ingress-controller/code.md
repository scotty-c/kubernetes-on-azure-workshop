# Ingress controller

In this module we are going to deploy the Azure ingress control that Azure has out of the box.    
This is not meant to be used for a production use as it is a single pod. To learn more about the restrictions    
please read [here](https://docs.microsoft.com/en-us/azure/aks/http-application-routing/?WT.mc_id=aksworkshop-github-sccoulto)  

To enable the add on 

## Enable the addon
`az aks enable-addons --resource-group k8s --name k8s --addons http_application_routing`

Now the addon is going to create a public DNS name to access the ingress control rules to get that DNS name  

## Get DNS name
`az aks show --resource-group k8s --name k8s --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName -o tsv`

Now we deploy our deployments with the ingress DNS name

## Deploying our application
```
#!/bin/bash

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: webapp-deployment
spec:
  selector:
    matchLabels:
      app: webapp
  replicas: 1
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
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 3000
  selector:
    app: webapp
  type: ClusterIP
EOF

DNS=$(az aks show --resource-group k8s --name k8s --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName -o tsv)

cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: webapp
  annotations:
    kubernetes.io/ingress.class: addon-http-application-routing
spec:
  rules:
  - host: webapp.$DNS
    http:
      paths:
      - backend:
          serviceName: webapp
          servicePort: 80
        path: /
EOF        
```


Now check your browser using http://webapp.$DNS
