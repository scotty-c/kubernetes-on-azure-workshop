# Deploying a public chart

## Deploying Consul

In this module we are going to deploy a public chart that use pvc's and replication
That chart is hashicorp's consul.

To deploy the chart

```
helm install --name consul --set StorageClass=default stable/consul
```

To watch the chart being deployed

```
kubectl get pods --namespace=default -w
```

To check the state of the stateful set

```
kubectl get pvc
```
