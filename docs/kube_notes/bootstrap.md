# Experiment for Kubernetes setup

We're experimenting with kube for deployment. These notes will have commands we're using to set that up.

## Env Explanation
- We are setup East US for SA support
- We are using a small 3 node cluster with B series nodes
- We're linking the dev AD group

## Commands

### Env Setup
```
RESOURCE_GROUP=redsol-RG
SUBSCRIPTION_ID=8b91797a-2975-47ad-95dd-5767ebf67c90
CLUSTER_NAME=redsol
LOCATION=eastus
VM_SIZE="Standard_B2s"
NODE_COUNT=3
APPDEV_NAME="dev"
ACR_NAME=redsolacr
```
- `RESOURCE_GROUP` is the containing resource group
- `SUBSCRIPTION_ID` is subscription id for the account
- `CLUSTER_NAME` the kubernetes cluster name
- `LOCATION` geography for the resource group
- `VM_SIZE` size of the cluster nodes
- `NODE_COUNT` number of nodes
- `APPDEV_NAME` AAD resource group for developer access
- `ACR_NAME` Name of the container registry

### Login
```
az login
az account set -s "${SUBSCRIPTION_ID}"
```

### Create AZ cluster
```
az group create --name $RESOURCE_GROUP \
                --location $LOCATION \
                --subscription $SUBSCRIPTION_ID

az aks create -g $RESOURCE_GROUP -n $CLUSTER_NAME \
              --node-vm-size $VM_SIZE \
              --nodecount $NODE_COUNT \
              --enable-managed-identity \
              --subscription $SUBSCRIPTION_ID

az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME \
            --query "identity" \
            --subscription $SUBSCRIPTION_ID
```

### Setup System [Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli)
```
az feature register --namespace Microsoft.ContainerService \
                     -n MigrateToMSIClusterPreview \
                     --subscription $SUBSCRIPTION_ID
az provider register -n Microsoft.ContainerService

az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME \
               --enable-aad \
               --subscription $SUBSCRIPTION_ID
```

### Setup Cluster Role Perms

#### User Perms
```
AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv --subscription $SUBSCRIPTION_ID) && \
APPDEV_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)&& \
az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster User Role" --scope $AKS_ID --subscription $SUBSCRIPTION_ID
```
#### Admin Perms
```
AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv --subscription $SUBSCRIPTION_ID) && \
APPDEV_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)&& \
az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster Admin Role" --scope $AKS_ID --subscription $SUBSCRIPTION_ID
```

### Setup [ACR Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal) for Containers
```
az acr create -g $RESOURCE_GROUP --name $ACR_NAME \
              --sku Basic \
              --subscription $SUBSCRIPTION_ID
```

#### Attach AKS cluster to ACR by name "acrName"
```
az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME \
            --attach-acr $ACR_NAME \
            --subscription $SUBSCRIPTION_ID
```



