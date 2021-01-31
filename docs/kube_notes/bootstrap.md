# Experiment for Kubernetes setup

We're experimenting with kube for deployment. These notes will have commands we're using to set that up.

Some docs on how to add [AAD steps](https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli#create-server-application)

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
LOCATION=EastUS
VM_SIZE="Standard_B2s"
NODE_COUNT=1
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

### Create AD app to integrate

```
# Create the Azure AD application
serverApplicationId=$(az ad app create \
    --display-name "${CLUSTER_NAME}Server" \
    --identifier-uris "https://${CLUSTER_NAME}Server" \
    --query appId -o tsv)

# Update the application group membership claims
az ad app update --id $serverApplicationId --set groupMembershipClaims=All
```

### Create Service Princapl

```
# Create a service principal for the Azure AD application
az ad sp create --id $serverApplicationId

# Get the service principal secret
serverApplicationSecret=$(az ad sp credential reset \
    --name $serverApplicationId \
    --credential-description "AKSPassword" \
    --query password -o tsv)
```

### Creare AD Permissions
```
az ad app permission add \
    --id $serverApplicationId \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

az ad app permission grant --id $serverApplicationId --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  $serverApplicationId
```

### Create an AD App and it's Service Principal

```
clientApplicationId=$(az ad app create \
    --display-name "${aksname}Client" \
    --native-app \
    --reply-urls "https://${aksname}Client" \
    --query appId -o tsv)

az ad sp create --id $clientApplicationId

oAuthPermissionId=$(az ad app show --id $serverApplicationId --query "oauth2Permissions[0].id" -o tsv)

az ad app permission add --id $clientApplicationId --api $serverApplicationId --api-permissions ${oAuthPermissionId}=Scope
az ad app permission grant --id $clientApplicationId --api $serverApplicationId
```


### Create AZ cluster
```
az group create --name $RESOURCE_GROUP \
                --location $LOCATION \
                --subscription $SUBSCRIPTION_ID

tenantId=$(az account show --query tenantId -o tsv)

az aks create \
    -g $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-vm-size $VM_SIZE \
    --node-count $NODE_COUNT \
    --load-balancer-sku Basic \
    --no-ssh-key \
    --enable-managed-identity \
    --aad-server-app-id $serverApplicationId \
    --aad-server-app-secret $serverApplicationSecret \
    --aad-client-app-id $clientApplicationId \
    --aad-tenant-id $tenantId \
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

#### Login as admin
```
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --subscription $SUBSCRIPTION_ID --admin
```

#### List system containers

```
kubectl get deployments --namespace kube-system
```

#### Configure Cluster RBAC

```
CURRENT_ID=$(az ad signed-in-user show --query userPrincipalName -o tsv)

GROUP_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)
cat << EOF | kubectl apply -f -
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev-admin
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
# from ;  
- kind: Group
  namespace: default
  name: $GROUP_ID
- kind: User
  namespace: default
  name: $CURRENT_ID
EOF
```

### Login and Test

```
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing --subscription $SUBSCRIPTION_ID
```

```
kubectl get deployments --namespace default
kubectl get pods --all-namespaces
```
