# Deploying a public chart

## Deploying Consul
```
helm install --name consul --set StorageClass=default stable/consul
```

```
kubectl get pods --namespace=default -w
```

```
kubectl get pvc
```
