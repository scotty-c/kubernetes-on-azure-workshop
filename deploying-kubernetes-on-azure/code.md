# Deploying Kubernetes on Azure

## Create a resource group
`az group create --name k8s --location eastus`

## Create your cluster
```
az aks create --resource-group k8s \
    --name k8s \
    --generate-ssh-keys \
    --kubernetes-version 1.12.6 \
    --enable-rbac \
    --node-vm-size Standard_DS2_v2
```

## If you dont have the kubectl binary installed
`az aks install-cli`

## Get your cluster credentials
`az aks get-credentials --resource-group k8s --name k8s`

## Test your cluster
`kubectl get nodes`
`kubectl get pods --all-namespaces`
