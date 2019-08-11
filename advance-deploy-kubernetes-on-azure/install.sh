#!/bin/bash

set -e
set -o pipefail

read -p "Enter the subscription to use: "  SUB
read -p "Enter region to deploy the cluster: "  LOCATION

az account set --subscription "$SUB"

VNET_RANGE=10.0.0.0/8  
CLUSTER_SUBNET_RANGE=10.240.0.0/16 
VN_SUBNET_RANGE=10.241.0.0/16 
VNET_NAME=k8sVNet
CLUSTER_SUBNET_NAME=k8sSubnet 
VN_SUBNET_NAME=VNSubnet 
AKS_CLUSTER_RG=vk-k8s
KUBE_DNS_IP=10.0.0.10
SP_NAME=virtual-node


pre_checks () {
az feature register --name EnableNetworkPolicy --namespace Microsoft.ContainerService
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableNetworkPolicy')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
RG_THERE=$(az group exists --name $AKS_CLUSTER_RG)
echo "Checking if the resource group exisits"
if [ $RG_THERE == true ]
then 
    echo "The resource group has already been created"
else
    echo "Creating the resource group"
    az group create -l $LOCATION -n $AKS_CLUSTER_RG
fi

SP_THERE=$(az ad sp list --display-name $SP_NAME -o table )
echo "Checking for pre created service principal"
if [ -z "$SP_THERE" ]
then
      echo "The service principal does not exsist"
else
      echo "Deleting service principal, we will recreate it later in the script"
      az ad sp delete --id http://$SP_NAME

fi
}

create_vnet () { 
az network vnet create \
    --resource-group $AKS_CLUSTER_RG \
    --name $VNET_NAME \
    --address-prefixes $VNET_RANGE \
    --subnet-name $CLUSTER_SUBNET_NAME \
    --subnet-prefix $CLUSTER_SUBNET_RANGE
}

create_subnet () {
az network vnet subnet create \
    --resource-group $AKS_CLUSTER_RG \
    --vnet-name $VNET_NAME \
    --name $VN_SUBNET_NAME \
    --address-prefix $VN_SUBNET_RANGE
}

create_aks () {
VNETID=$(az network vnet show --resource-group $AKS_CLUSTER_RG --name $VNET_NAME --query id -o tsv)
AZURE_CLIENT_SECRET=$(az ad sp create-for-rbac --name $SP_NAME --role Contributor | jq -r .password)
AZURE_CLIENT_ID=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)
AZURE_TENANT_ID=$(az ad sp show --id http://$SP_NAME --query appOwnerTenantId --output tsv )
export AZURE_CLIENT_ID
export AZURE_TENANT_ID
export AZURE_CLIENT_SECRET
echo ""
echo "The client secret is $AZURE_CLIENT_SECRET"
VNET_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_CLUSTER_RG --vnet-name $VNET_NAME --name $CLUSTER_SUBNET_NAME --query id -o tsv)
az role assignment create --assignee $AZURE_CLIENT_ID --scope $VNETID --role Contributor
az aks create \
    --resource-group $AKS_CLUSTER_RG \
    --name vk-k8s \
    --node-count 3 \
    --kubernetes-version 1.14.0 \
    --network-plugin azure \
    --service-cidr 10.0.0.0/16 \
    --dns-service-ip $KUBE_DNS_IP \
    --docker-bridge-address 172.17.0.1/16 \
    --vnet-subnet-id $VNET_SUBNET_ID \
    --service-principal $AZURE_CLIENT_ID \
    --client-secret $AZURE_CLIENT_SECRET \
    --network-policy calico

az aks get-credentials --resource-group $AKS_CLUSTER_RG --name vk-k8s --admin --overwrite-existing 
kubectx $SP_NAME=vk-k8s-admin
}

install_helm() {
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF
helm init --service-account tiller
echo "Waiting for Tiller to be available"
sleep 60
}


create_virtual_node () {
az aks enable-addons \
    --resource-group $AKS_CLUSTER_RG \
    --name vk-k8s \
    --addons $SP_NAME \
    --subnet-name $VN_SUBNET_NAME
}

pre_checks
create_vnet
create_subnet
create_aks
install_helm
create_virtual_node