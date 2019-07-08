# Deploying Kubernetes on Azure

In this module we are going to install Kubernetes on Azure. The first thing we  
need to do is create a resource group.  

Please note you do not need to use `eastus` you can create a resource group in an region. 
If you are in Australaia I would suggest `australiaeast` 

## Create a resource group
`az group create --name k8s --location eastus`

Next we are going to create the AKS cluster. If you are using a trial account you will need to change the machine size `v1`

## Create your cluster
```
az aks create --resource-group k8s \
    --name k8s \
    --generate-ssh-keys \
    --kubernetes-version 1.14.0 \
    --enable-rbac \
    --node-vm-size Standard_DS2_v2
```

Next install the `kubectl` binary if you dont already have it installed. Now if you are using cloud shell you can skip this step as it is already installed.

## If you dont have the kubectl binary installed
`az aks install-cli`

## Get your cluster credentials
This command will download the credentials from your cluster. These credentials are the admin credentials for the cluster.
So in a production cluster be careful with who has these.  
`az aks get-credentials --resource-group k8s --name k8s`

## Test your cluster
Now our cluster is up and running let's run a few commands that will show use what we have deployed so far.  
To look at our nodes we will issue the following command  
`kubectl get nodes`   
Then to look at the pods we have issues the following  
`kubectl get pods --all-namespaces`
