# Deploying Kubernetes on Azure

In this module we are going to create an aks cluster with the following addons
* Azure CNI
* Virtual node
* Calico network policy

To make the cluster creation easier there has been a [script](install.sh)

The cluster will now create a [service principal](https://docs.microsoft.com/azure/active-directory/develop/app-objects-and-service-principals?WT.mc_id=workshop-github-sccoulto) then a 3 node AKS cluster using  
the [Azure cni plugin](https://docs.microsoft.com/azure/aks/configure-azure-cni?WT.mc_id=workshop-github-sccoulto) using Calico as the provider. 

## To run the script 
First make sure you have downloaded the workshop container #TODO add link when merged to master   
Once you are in the containers shell git clone the repo ` git clone https://github.com/scotty-c/kubernetes-on-azure-workshop.git`    
Then `cd advance-deploy-kubernetes-on-azure && chmod +x install.sh`  
We can then run the script `./install.sh`  


## Lets breakdown what the script is doing

The first thing the script will do is ask you two questions
```bash
read -p "Enter the subscription to use: "  SUB
read -p "Enter region to deploy the cluster: "  LOCATION
```

To get your subscription name you can use the following command `az account list -o table`  
To get the region name use the following 
```bash
$ az account list-locations -o table
DisplayName          Latitude    Longitude    Name
-------------------  ----------  -----------  ------------------
East Asia            22.267      114.188      eastasia
Southeast Asia       1.283       103.833      southeastasia
Central US           41.5908     -93.6208     centralus
East US              37.3719     -79.8164     eastus
East US 2            36.6681     -78.3889     eastus2
West US              37.783      -122.417     westus
North Central US     41.8819     -87.6278     northcentralus
South Central US     29.4167     -98.5        southcentralus
North Europe         53.3478     -6.2597      northeurope
West Europe          52.3667     4.9          westeurope
Japan West           34.6939     135.5022     japanwest
Japan East           35.68       139.77       japaneast
Brazil South         -23.55      -46.633      brazilsouth
Australia East       -33.86      151.2094     australiaeast
Australia Southeast  -37.8136    144.9631     australiasoutheast
South India          12.9822     80.1636      southindia
Central India        18.5822     73.9197      centralindia
West India           19.088      72.868       westindia
Canada Central       43.653      -79.383      canadacentral
Canada East          46.817      -71.217      canadaeast
UK South             50.941      -0.799       uksouth
UK West              53.427      -3.084       ukwest
West Central US      40.890      -110.234     westcentralus
West US 2            47.233      -119.852     westus2
Korea Central        37.5665     126.9780     koreacentral
Korea South          35.1796     129.0756     koreasouth
France Central       46.3772     2.3730       francecentral
France South         43.8345     2.1972       francesouth
Australia Central    -35.3075    149.1244     australiacentral
Australia Central 2  -35.3075    149.1244     australiacentral2
South Africa North   -25.731340  28.218370    southafricanorth
South Africa West    -34.075691  18.843266    southafricawest
```

The script will then create a resource group called `vk-k8s` and the make sure you have the networking policy feature enabled for Calico. 
```bash
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
```
Next the script creates a vnet and a subnet  
```bash
az network vnet create \
    --resource-group $AKS_CLUSTER_RG \
    --name $VNET_NAME \
    --address-prefixes $VNET_RANGE \
    --subnet-name $CLUSTER_SUBNET_NAME \
    --subnet-prefix $CLUSTER_SUBNET_RANGE

az network vnet subnet create \
    --resource-group $AKS_CLUSTER_RG \
    --vnet-name $VNET_NAME \
    --name $VN_SUBNET_NAME \
    --address-prefix $VN_SUBNET_RANGE
```

The next step is to a service principal for the cluster and assign a role
```bash
VNETID=$(az network vnet show --resource-group $AKS_CLUSTER_RG --name $VNET_NAME --query id -o tsv)
AZURE_CLIENT_SECRET=$(az ad sp create-for-rbac --name $SP_NAME --role Contributor | jq -r .password)
AZURE_CLIENT_ID=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)
AZURE_TENANT_ID=$(az ad sp show --id http://$SP_NAME --query appOwnerTenantId --output tsv )
VNET_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_CLUSTER_RG --vnet-name $VNET_NAME --name $CLUSTER_SUBNET_NAME --query id -o tsv)
az role assignment create --assignee $AZURE_CLIENT_ID --scope $VNETID --role Contributor
```

Then we create our cluster 
```bash
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
```

Next we install helm which is a dependancy for virtual node
```bash
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
 ```

Lastly we will enable the virtual node feature to our cluster
```bash
az aks enable-addons \
    --resource-group $AKS_CLUSTER_RG \
    --name vk-k8s \
    --addons $SP_NAME \
    --subnet-name $VN_SUBNET_NAME
```
