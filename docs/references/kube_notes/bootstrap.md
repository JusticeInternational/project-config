# Getting a working Kubernetes setup on AZ

We're working with kube for deployment on Azure. These notes will have commands we're using to set that up.

Some docs on how to add [AAD steps](https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli#create-server-application)

## Env Explanation
- We are setup East US for SA support
- We are using a small 1 node cluster with B series nodes to save for development but we should use 3 in production
- We're linking the dev AD group for permissions

## Command setup and steps

Several of the steps below were done during troubleshooting and developing a plan for how we would setup the cluster. Most of those commands have either been removed or summarized into scripts that were functional for our use. 

This docs notes are scripted out as follows:

1. Env config is in [`/script/env_source.sh`](/script/env_source.sh)
1. Create the instance with [`/script/create_instance.sh`](/script/create_instance.sh)
1. Attach an acr registry to k8s with [`/script/attach_acr.sh`](/script/attach_acr.sh)
1. Setup permissions with [`/script/assign_permissions.sh`](/script/assign_permissions.sh)
1. Create ingress with [`/script/create_ingress.sh`](/script/create_ingress.sh)
1. Create KeyVault integration with k8s with [`/script/create_azkv_k9s.sh`](/script/create_azkv_k9s.sh)
1. Setup a demo app for testing with [`/script/demo?_app.sh`](/script/demo_app.sh)

If your trouble shooting the rest of the doc could be useful for following and understanding what we're doing in each script.

### Env Setup `env_source.sh`
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
    --display-name "${CLUSTER_NAME}Client" \
    --native-app \
    --reply-urls "https://${CLUSTER_NAME}Client" \
    --query appId -o tsv)

az ad sp create --id $clientApplicationId

oAuthPermissionId=$(az ad app show --id $serverApplicationId --query "oauth2Permissions[0].id" -o tsv)

az ad app permission add --id $clientApplicationId --api $serverApplicationId --api-permissions ${oAuthPermissionId}=Scope
az ad app permission grant --id $clientApplicationId --api $serverApplicationId
```
### Create Resource Group

```
az group create --name $RESOURCE_GROUP \
                --location $LOCATION \
                --subscription $SUBSCRIPTION_ID
```

### Setup Network
From [this article](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni), we'll setup the network:

```
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name "${RESOURCE_GROUP}_vnet" \
    --address-prefixes 192.168.0.0/16 \
    --subnet-name "${RESOURCE_GROUP}_subnet" \
    --subnet-prefix 192.168.1.0/24 \
    --subscription $SUBSCRIPTION_ID
```

```

VNET_ID=$(az network vnet show \
            --resource-group ${RESOURCE_GROUP} \
            --name "${RESOURCE_GROUP}_vnet" --query id -o tsv \
            --subscription $SUBSCRIPTION_ID)
SUBNET_ID=$(az network vnet subnet show \
              --resource-group ${RESOURCE_GROUP} \
              --vnet-name "${RESOURCE_GROUP}_vnet" \
              --name "${RESOURCE_GROUP}_subnet" \
              --query id -o tsv \
              --subscription $SUBSCRIPTION_ID)
```

Give permissions
```
APP_ID=$(az ad app show --id $serverApplicationId --query "appId" -o tsv)
az role assignment create --assignee $APP_ID --scope $VNET_ID --role "Network Contributor"
```

### Create AZ cluster `create_instance.sh`
```

tenantId=$(az account show --query tenantId -o tsv)

az identity create --name "${CLUSTER_NAME}_id" --resource-group $RESOURCE_GROUP --subscription $SUBSCRIPTION_ID
ASSIGN_ID=$(az identity list --query "[].{name:name, Id:id}"|jq -r '.[] | select(.name=="'${CLUSTER_NAME}_id'")|.Id')

az aks create \
    -g $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-vm-size $VM_SIZE \
    --node-count $NODE_COUNT \
    --load-balancer-sku basic \
    --vm-set-type AvailabilitySet \
    --no-ssh-key \
    --enable-managed-identity \
    --aad-server-app-id $serverApplicationId \
    --aad-server-app-secret $serverApplicationSecret \
    --aad-client-app-id $clientApplicationId \
    --aad-tenant-id $tenantId \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --assign-identity $ASSIGN_ID \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --service-principal msi \
    --client-secret null \
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

### Setup Cluster Role Perms `assign_permissions.sh`

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
- [note about bug](https://github.com/Azure/AKS/issues/1517#issuecomment-634551363)
```
az acr create -g $RESOURCE_GROUP --name $ACR_NAME \
              --sku Basic \
              --subscription $SUBSCRIPTION_ID
```

#### Attach AKS cluster to ACR by name "acrName" `attach_acr.sh`
```
az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME \
            --attach-acr $ACR_NAME \
            --subscription $SUBSCRIPTION_ID
```
##### Workaround for failure
Since we're getting this failure:
```
❯ az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME \
            --attach-acr $ACR_NAME \
            --subscription $SUBSCRIPTION_ID
Waiting for AAD role to propagate[################################    ]  90.0000%Could not create a role assignment for ACR. Are you an Owner on this 
```
We're going to work around it by setting up username and password for pulls to registry.
1. Login to portal and enable Access Keys for username and password
1. Record the username and password in two env vars and set the registry url:
   ```
   export AKS_DOCKER_USERNAME=<username>
   export AKS_DOCKER_PASSWORD=<password>
   export ACR_REGISTRY="${ACR_NAME}.azurecr.io"
   ```
2. Login to az command line; `az login`
3. Login to aks : `az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --subscription $SUBSCRIPTION_ID --admin`
4. Use kubectl to create a secret ([as described here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes)):
   ```
   kubectl --namespace human-connection \
    create secret docker-registry acrregistrycreds \
    --docker-server="${ACR_REGISTRY}" \
    --docker-password="${AKS_DOCKER_PASSWORD}" \
    --docker-username="${AKS_DOCKER_USERNAME}"
   ```
#### Login as admin
```
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --subscription $SUBSCRIPTION_ID --admin
```

#### List system containers

```
kubectl get deployments --namespace kube-system
```

#### Configure Cluster RBAC `assign_permissions.sh`

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

### Setting up AKS ingress controller `create_ingress.sh`
Lets setup inbound access to services with [these instructions](https://docs.microsoft.com/en-us/azure/aks/ingress-basic).

```
# Create a namespace for your ingress resources
kubectl create namespace ingress-basic

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux
```

#### Test ingress `demo_app?.sh`
Test it with [this app demo](https://docs.microsoft.com/en-us/azure/aks/ingress-basic#run-demo-applications).