# Experiment for Kubernetes setup

We're experimenting with kube for deployment. These notes will have commands we're using to set that up.

## Env Explanation
- We are setup East US for SA support
- We are using a small 3 node cluster with B series nodes
- We're linking the dev AD group

## Commands


# perform work

RESOURCE_GROUP=redsol-RG
SUBSCRIPTION_ID=8b91797a-2975-47ad-95dd-5767ebf67c90
CLUSTER_NAME=redsol

LOCATION=erastus

# login as a user and set the appropriate subscription ID
az login
az account set -s "${SUBSCRIPTION_ID}"


az group create --name $RESOURCE_GROUP --location $LOCATION --subscription $SUBSCRIPTION_ID

az aks create -g $RESOURCE_GROUP -n $CLUSTER_NAME --node-vm-size Standard_B2s --nodecount 3 --enable-managed-identity --subscription $SUBSCRIPTION_ID

az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query "identity" --subscription $SUBSCRIPTION_ID

az feature register --namespace Microsoft.ContainerService -n MigrateToMSIClusterPreview --subscription $SUBSCRIPTION_ID

Once the feature 'MigrateToMSIClusterPreview' is registered, invoking 'az provider register -n Microsoft.ContainerService' is required to get the change propagated



az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME --enable-aad --subscription $SUBSCRIPTION_ID

az feature register --namespace Microsoft.ContainerService -n UserAssignedIdentityPreview --subscription $SUBSCRIPTION_ID


# https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli creating user assigned identity

# get the user identity resource

 echo $USERASSIGNED_ID

az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME --enable-aad --assign-identity $USERASSIGNED_ID --subscription $SUBSCRIPTION_ID




# access to cluster user role
APPDEV_NAME="dev" && \
AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv --subscription $SUBSCRIPTION_ID) && \
APPDEV_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)&& \
az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster User Role" --scope $AKS_ID --subscription $SUBSCRIPTION_ID

# access to admin role
APPDEV_NAME="TM-GHAE-ReadWrite-32f8" && \
AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv --subscription $SUBSCRIPTION_ID) && \
APPDEV_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)&& \
az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster Admin Role" --scope $AKS_ID --subscription $SUBSCRIPTION_ID

# create acr registry

Create An ACR registry and attach it to an existing cluster
RESOURCE_GROUP=ghae-usage-service-wenlock
SUBSCRIPTION_ID=3cb2ced7-3c38-400d-9d1e-2d745573a98d
CLUSTER_NAME=ghae-usage-wenlock
ACR_NAME=guwenlockacr

# creating an ACR service principal ; https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal

# Create acr cluster https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli

az acr create -g $RESOURCE_GROUP --name $ACR_NAME --sku Basic --subscription $SUBSCRIPTION_ID


# Attach AKS cluster to ACR by name "acrName"
        az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME --attach-acr $ACR_NAME --subscription $SUBSCRIPTION_ID



