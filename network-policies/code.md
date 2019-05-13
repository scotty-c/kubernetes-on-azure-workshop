# Network policies

In this module we are going to set up a simple webservice that will act as our backend.  
Then we are going to set up network policies to restrict access to the service.

The first thing that we are going to do is create a namespace called development.

`kubectl create namespace development`

We will then label our namespace so we can use that in our network policies later.

`kubectl label namespace/development purpose=development`

We will then deploy our application   

```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: development
spec:
  selector:
    matchLabels:
      app: webapp
  replicas: 1
  template:
    metadata:
      labels:
        app: webapp
        role: backend
    spec:
      containers:
      - name: webapp
        image: scottyc/webapp:latest
        ports:
        - containerPort: 3000
          hostPort: 3000
EOF
```

The next task is to create a service to expose our application

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: development
spec:
  type: ClusterIP
  selector:
    app: webapp
    role: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
EOF    
```

We will then create a pod and exec into that pods shell.  
`kubectl run --rm -it --image=alpine network-policy --namespace development --generator=run-pod/v1`  
Once we are in the shell lets hit the backend service with the below `wget` command  
`wget -qO- http://webapp-service`

Once you have hit the service you can exit that pods shell with the `exit` command in that terminal session.

Now lets create a network policy that blocks all ingress to our application  
```
cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: backend-policy
  namespace: development
spec:
  podSelector:
    matchLabels:
      app: webapp
      role: backend
  ingress: []
EOF
```
Now we can test that our policy works by creating our test pod and again get shell access.  
`kubectl run --rm -it --image=alpine network-policy --namespace development --generator=run-pod/v1`  
Once we are in the shell lets hit the backend service with the below `wget` command  
`wget -qO- --timeout=2 http://webapp-service`

If all goes well you should have got the following output `wget: download timed out` which is what we were expecting as we blocked all ingress to our service.  

Once you have hit the service you can exit that pods shell with the `exit` command in that terminal session.  

Now blocking all traffic to our applications is not the most suitable approach in the real world. So let's look at applying network policies to labels on pods. We will now make changes to our policy to only allow traffic from our frontend.

```
cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: backend-policy
  namespace: development
spec:
  podSelector:
    matchLabels:
      app: webapp
      role: backend
  ingress:
  - from:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          app: webapp
          role: frontend
EOF
```          

So lets test this policy the same way we have in the past.  
`kubectl run --rm -it --image=alpine network-policy --namespace development --generator=run-pod/v1`  

`wget -qO- --timeout=2 http://webapp-service`

Let's close that shell with the `exit` command

Now that didn't work. The reason for that are we are working on labels to allow traffic. With our pod that we just created we did not have the correct labels. Only a pod tagged with the label of `frontend` will have access to the backend service. Let's try again with the correct labels.  
`kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace development --generator=run-pod/v1`  

`wget -qO- --timeout=2 http://webapp-service`

Now that `wget` call is successful. Let's close that shell with the `exit` command.  

The next thing that we need to look at is cross namespace traffic. As we know networking is not name spaced.  

Now let's create a namespace called production
`kubectl create namespace production`  
`kubectl label namespace/production purpose=production`  

If we run our frontend pod from the production namespace will we be able to hit the development backend? Let's try it out.

`kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace production --generator=run-pod/v1`  

`wget -qO- http://webapp-service.development`

Let's close that shell with the `exit` command. 

So we could hit the development backend service from the production namespace due to our network policy only filtering on labels, remembering that networking is not namespaced.

Let's make a change to our policy to make sure only services in side the development namespace is are allowed to talk to our backend service.


```
cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: backend-policy
  namespace: development
spec:
  podSelector:
    matchLabels:
      app: webapp
      role: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: development
      podSelector:
        matchLabels:
          app: webapp
          role: frontend
EOF
```

Again we will spin up our front end pod in the production namespace and test again if we can hit our backend in the development namespace.
`kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace production --generator=run-pod/v1`  

`wget -qO- --timeout=2 http://webapp-service.development`  

If we have done everything correctly we should get our `wget: download timed out` error