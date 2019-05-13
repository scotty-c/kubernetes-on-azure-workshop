# Deploying Kubernetes on Azure

## Register EnableNetworkPolicy 

`az feature register --name EnableNetworkPolicy --namespace Microsoft.ContainerService`

Check to see if it is registered   
`az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableNetworkPolicy')].{Name:name,State:properties.state}"`  

Refresh the Microsoft.ContainerService  
`az provider register --namespace Microsoft.ContainerService`  

## Create a resource group
`az group create --name k8s --location eastus`

## Create your cluster
To create your cluster please use the script [here](install.sh)

The cluster will now create a [service principal](https://docs.microsoft.com/azure/active-directory/develop/app-objects-and-service-principals?WT.mc_id=workshop-github-sccoulto) then a 3 node AKS cluster using  
the [Azure cni plugin](https://docs.microsoft.com/azure/aks/configure-azure-cni?WT.mc_id=workshop-github-sccoulto) using Calico as the provider. 

