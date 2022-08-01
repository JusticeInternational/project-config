#!/bin/bash

set -x -v -e

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh

# Setup AGIC: https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing
# create a public IP for AKS
# https://docs.microsoft.com/en-us/azure/aks/static-ip
az network public-ip create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}-ip" \
    --sku ${PUBLIC_IP_SKU_NAME} \
    --allocation-method Static \
    --subscription "${SUBSCRIPTION_ID}"

# Just informational for us
public_ip=$(az network public-ip show \
   --resource-group "${RESOURCE_GROUP}" \
   --name "${CLUSTER_NAME}-ip" \
   --query ipAddress --output tsv --subscription "${SUBSCRIPTION_ID}")

az network vnet create \
    --name "${CLUSTER_NAME}-Vnet" \
    --resource-group "${RESOURCE_GROUP}" \
    --address-prefix 11.0.0.0/8 \
    --subnet-name "${CLUSTER_NAME}-Subnet" \
    --subnet-prefix 11.1.0.0/16  \
    --subscription "${SUBSCRIPTION_ID}"

az network application-gateway create \
    --name "${CLUSTER_NAME}-Gateway" \
    --resource-group "${RESOURCE_GROUP}" \
    -l "${LOCATION}" \
    --sku ${APPGW_SKU_NAME} \
    --public-ip-address "${CLUSTER_NAME}-ip" \
    --vnet-name "${CLUSTER_NAME}-Vnet" \
    --subnet "${CLUSTER_NAME}-Subnet" \
    --subscription "${SUBSCRIPTION_ID}"

appgwId=$(az network application-gateway show \
            --name "${CLUSTER_NAME}-Gateway" \
            --resource-group "${RESOURCE_GROUP}" \
            -o tsv \
            --query "id" \
            --subscription "${SUBSCRIPTION_ID}") 

az aks enable-addons \
    --name "${CLUSTER_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    -a ingress-appgw --appgw-id $appgwId \
    --subscription "${SUBSCRIPTION_ID}"

# peer
nodeResourceGroup=$(az aks show \
    --name "${CLUSTER_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    -o tsv --query "nodeResourceGroup" \
    --subscription "${SUBSCRIPTION_ID}") 

aksVnetName=$(az network vnet list \
    --resource-group "${nodeResourceGroup}" \
    --subscription "${SUBSCRIPTION_ID}" | \
    jq -r '.[]|select("'${nodeResourceGroup}'" == .resourceGroup)| .name') 

aksVnetId=$(az network vnet show \
    --name $aksVnetName \
    --resource-group "${nodeResourceGroup}" \
    -o tsv --query "id" \
    --subscription "${SUBSCRIPTION_ID}") 

az network vnet peering create \
    --name "${CLUSTER_NAME}-GW2AKS-VnetPeering" \
    --resource-group "${RESOURCE_GROUP}" \
    --vnet-name "${CLUSTER_NAME}-Vnet" \
    --remote-vnet $aksVnetId \
    --allow-vnet-access \
    --subscription "${SUBSCRIPTION_ID}"

appGWVnetId=$(az network vnet show \
   --name "${CLUSTER_NAME}-Vnet" \
   --resource-group "${RESOURCE_GROUP}" \
   -o tsv --query "id" \
   --subscription "${SUBSCRIPTION_ID}")

az network vnet peering create \
   --name "${CLUSTER_NAME}-AKS2GW-VnetPeering" \
   --resource-group "$nodeResourceGroup" \
   --vnet-name $aksVnetName \
   --remote-vnet $appGWVnetId \
   --allow-vnet-access \
   --subscription "${SUBSCRIPTION_ID}"

# apply sample app
kubectl apply \
 -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml 

# check ingress
kubectl get ingress
