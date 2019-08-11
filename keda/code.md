# Keda 

## Installing Keda

#### Add Helm repo
```
helm repo add kedacore https://kedacore.azureedge.net/helm
```

#### Update Helm repo
```
helm repo update
```

#### Install keda-edge chart
```
helm install kedacore/keda-edge --devel --set logLevel=debug --namespace keda --name keda
```

#### Install rabbitmq
```
helm install --name rabbitmq --set rabbitmq.username=user,rabbitmq.password=PASSWORD stable/rabbitmq
```

#### Install consumer
```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq-consumer
  namespace: default
  labels:
    app: rabbitmq-consumer
spec:
  selector:
    matchLabels:
      app: rabbitmq-consumer
  template:
    metadata:
      labels:
        app: rabbitmq-consumer
    spec:
      containers:
      - name: rabbitmq-consumer
        image: jeffhollan/rabbitmq-client:dev
        imagePullPolicy: Always
        command:
          - receive
        args:
          - 'amqp://user:PASSWORD@rabbitmq.default.svc.cluster.local:5672'
      dnsPolicy: ClusterFirst
      nodeSelector:
        kubernetes.io/role: agent
        beta.kubernetes.io/os: linux
        type: virtual-kubelet
      tolerations:
      - key: virtual-kubelet.io/provider
        operator: Exists
      - key: azure.com/aci
        effect: NoSchedule      
---
apiVersion: keda.k8s.io/v1alpha1
kind: ScaledObject
metadata:
  name: rabbitmq-consumer
  namespace: default
  labels:
    deploymentName: rabbitmq-consumer
spec:
  scaleTargetRef:
    deploymentName: rabbitmq-consumer
  pollingInterval: 5   # Optional. Default: 30 seconds
  cooldownPeriod: 30   # Optional. Default: 300 seconds
  maxReplicaCount: 30  # Optional. Default: 100
  triggers:
  - type: rabbitmq
    metadata:
      queueName: hello
      host: 'amqp://user:PASSWORD@rabbitmq.default.svc.cluster.local:5672'
      queueLength  : '5'
EOF
```

#### Set up our terminal
Before we deploy our consumer we will need to open up a couple of terminals to see how the horizontal pod autoscaler is going to scale our workloads across to ACI using virtual node. As we are working in a container we will use tmux to help us. First step if you have not already done so open tmux by typing `tmux`

Next we will create a new window by pressing `ctrl+b c`  
Then split that window with `ctrl+b %`  

you can now move around the windows with `ctrl+b ->` (Arrow keys)  

In one window enter `kubectl get hpa -w` to watch the horizontal pod autoscaler  
In the other enter `kubectl get pods -o wide` to make sure our pods are being scheduled on virtual node.  

now switch back to our first window with `ctrl+b n`

#### Install the publisher
```
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: rabbitmq-publish
spec:
  template:
    spec:
      containers:
      - name: rabbitmq-client
        image: jeffhollan/rabbitmq-client:dev
        imagePullPolicy: Always
        command: ["send",  "amqp://user:PASSWORD@rabbitmq.default.svc.cluster.local:5672", "300"]
      restartPolicy: Never
  backoffLimit: 4
EOF
```

Now let's switch back to our second window to watch the scaling events `ctrl+b n`


## Clean up
This is super important for the next modules not to have any resources left over.
```
kubectl delete job rabbitmq-publish
kubectl delete ScaledObject rabbitmq-consumer
kubectl delete deploy rabbitmq-consumer
helm delete --purge rabbitmq
```