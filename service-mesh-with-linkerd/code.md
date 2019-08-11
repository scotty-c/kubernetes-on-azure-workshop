# Service mesh with Linkerd

In this module we will install [Linkerd](https://linkerd.io/) and look at traffic going between meshed applications. 

## Installing Linkerd 

To install Linkerd on your cluster you issue the following command  

```
linkerd install | kubectl apply -f -
```
Linkerd will install the following on your cluster  

```
lusterrole.rbac.authorization.k8s.io/linkerd-linkerd-identity created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-identity created
serviceaccount/linkerd-identity created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-controller created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-controller created
serviceaccount/linkerd-controller created
serviceaccount/linkerd-web created
customresourcedefinition.apiextensions.k8s.io/serviceprofiles.linkerd.io created
customresourcedefinition.apiextensions.k8s.io/trafficsplits.split.smi-spec.io created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-prometheus created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-prometheus created
serviceaccount/linkerd-prometheus created
serviceaccount/linkerd-grafana created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector created
serviceaccount/linkerd-proxy-injector created
secret/linkerd-proxy-injector-tls created
mutatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-proxy-injector-webhook-config created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator created
serviceaccount/linkerd-sp-validator created
secret/linkerd-sp-validator-tls created
validatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-sp-validator-webhook-config created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-tap created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-tap created
serviceaccount/linkerd-tap created
podsecuritypolicy.policy/linkerd-linkerd-control-plane created
role.rbac.authorization.k8s.io/linkerd-psp created
rolebinding.rbac.authorization.k8s.io/linkerd-psp created
configmap/linkerd-config created
secret/linkerd-identity-issuer created
service/linkerd-identity created
deployment.extensions/linkerd-identity created
service/linkerd-controller-api created
service/linkerd-destination created
deployment.extensions/linkerd-controller created
service/linkerd-web created
deployment.extensions/linkerd-web created
configmap/linkerd-prometheus-config created
service/linkerd-prometheus created
deployment.extensions/linkerd-prometheus created
configmap/linkerd-grafana-config created
service/linkerd-grafana created
deployment.extensions/linkerd-grafana created
deployment.apps/linkerd-proxy-injector created
service/linkerd-proxy-injector created
service/linkerd-sp-validator created
deployment.extensions/linkerd-sp-validator created
service/linkerd-tap created
deployment.extensions/linkerd-tap created
```
We are going to take advantage of Linkerd's auto injection functionality to inject the envoy proxy into our application. Auto injections is done on the namespace, so we are going to create a new namespace. 

```
kubectl create namespace mesh-app
```
We are then going to add the label to tell Linkerd to auto inject on this namespace  
```
kubectl annotate namespace mesh-app linkerd.io/inject=enabled
```

Next we are going to deploy a web application ands use it as a mock service api

```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: webapp-deployment
  namespace: mesh-app
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
```

We will then expose the application using a service type

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: mesh-app
spec:
  type: ClusterIP
  selector:
    app: webapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
EOF  
```
In a new terminal let's open up the Linkerd dashboard
```
linkerd dashboard &
```
We should see our namespace 


```
kubectl run --rm -it --image=alpine mesh-test --namespace mesh-app --generator=run-pod/v1

```

```
wget -qO- http://webapp-service

```
```
<!DOCTYPE html>
<html>
<head>
<title>
</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style type="text/css">
body {background-color:ffffff;background-repeat:no-repeat;background-position:top left;background-attachment:fixed;}
h1{text-align:center;font-family:Impact;color:000000;}
p {text-align:center;font-family:Verdana;font-size:14px;font-style:normal;font-weight:normal;color:000000;}
</style>
</head>
<body>
<h1>Awesome Web App !!!!</h1>
<p>....and the demo worked :)</p>
 <p><img src="https://media.giphy.com/media/iPTTjEt19igne/giphy.gif" alt="gif"></p>
 </body>
</html>
```

```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: hey-deployment
  namespace: mesh-app
spec:
  selector:
    matchLabels:
      app: hey
  replicas: 1
  template:
    metadata:
      labels:
        app: hey
    spec:
      containers:
      - name: hey
        image: scottyc/hey:latest
        args: ["-z", "20m", "http://webapp-service"]
EOF
```


```
kubectl delete -n mesh-app deployments.apps hey-deployment
```