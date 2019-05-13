#!/bin/bash

set -e
set -o pipefail

 VNET_RANGE=10.0.0.0/8  
 CLUSTER_SUBNET_RANGE=10.240.0.0/16 
 VNET_NAME=k8sVNet
 CLUSTER_SUBNET_NAME=k8sSubnet 
 AKS_CLUSTER_RG=k8s
 KUBE_DNS_IP=10.0.0.10
 SP_NAME=k8s-sp


create_vnet () { 
az network vnet create \
    --resource-group $AKS_CLUSTER_RG \
    --name $VNET_NAME \
    --address-prefixes $VNET_RANGE \
    --subnet-name $CLUSTER_SUBNET_NAME \
    --subnet-prefix $CLUSTER_SUBNET_RANGE
}

create_aks () {
VNETID=$(az network vnet show --resource-group $AKS_CLUSTER_RG --name $VNET_NAME --query id -o tsv)
AZURE_CLIENT_SECRET=$(az ad sp create-for-rbac --name $SP_NAME --skip-assignment | jq -r .password)
AZURE_CLIENT_ID=$(az ad sp show --id http://$SP_NAME --query [appId] --output tsv)
echo ""
echo "The client secret is $AZURE_CLIENT_SECRET"
VNET_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_CLUSTER_RG --vnet-name $VNET_NAME --name $CLUSTER_SUBNET_NAME --query id -o tsv)
# Wait 15 seconds to make sure that service principal has propagated
echo "Waiting for service principal to propagate..."
sleep 15
echo "Creating Azure role"
az role assignment create --assignee $AZURE_CLIENT_ID --scope $VNETID --role Contributor
echo "Creating AKS cluster"
az aks create \
    --resource-group $AKS_CLUSTER_RG \
    --name k8s \
    --node-count 3 \
    --kubernetes-version 1.11.8 \
    --generate-ssh-keys \
    --network-plugin azure \
    --service-cidr 10.0.0.0/16 \
    --dns-service-ip $KUBE_DNS_IP \
    --docker-bridge-address 172.17.0.1/16 \
    --vnet-subnet-id $VNET_SUBNET_ID \
    --service-principal $AZURE_CLIENT_ID \
    --client-secret $AZURE_CLIENT_SECRET \
    --network-policy calico

echo "Getting credentials"
az aks get-credentials --resource-group $AKS_CLUSTER_RG --name k8s --admin --overwrite-existing 
kubectx personal-cluster=k8s-admin
}

create_vnet
create_aks