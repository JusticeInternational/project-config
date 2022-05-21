#!/bin/bash

set -x -v
set -e

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh || echo "warning: login issues but will continue"

# # Create the Azure AD application
# serverApplicationId="$(az ad app list| jq '[.[]| { name: .displayName, id: .appId}]' | jq -r '.[]|select("'${CLUSTER_NAME}Server'" == .name)|.id')"
# if [ -z "${serverApplicationId}" ]; then
# serverApplicationId=$(az ad app create \
#                         --display-name "${CLUSTER_NAME}Server" \
#                         --identifier-uris "https://${CLUSTER_NAME}Server" \
#                         --query appId -o tsv)
# fi
# echo "serverApplicaitonId ==> ${serverApplicationId}"

# # Update the application group membership claims
# az ad app update --id $serverApplicationId --set groupMembershipClaims=All


# # Create a service principal for the Azure AD application
# az ad sp list --all| jq '.[]|select( "'$serverApplicationId'" == .appId)' > /dev/null || \
#   az ad sp create --id $serverApplicationId

# # Get the service principal secret
# serverApplicationSecret=$(az ad sp credential reset \
#                             --name $serverApplicationId \
#                             --credential-description "AKSPassword" \
#                             --query password -o tsv)

# # create ad permissions
# az ad app permission add \
#     --id $serverApplicationId \
#     --api 00000003-0000-0000-c000-000000000000 \
#     --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

# az ad app permission grant --id $serverApplicationId --api 00000003-0000-0000-c000-000000000000
# az ad app permission admin-consent --id  $serverApplicationId

# # create ad app

# clientApplicationId="$(az ad app list| jq '[.[]| { name: .displayName, id: .appId}]' | jq -r '.[]|select("'${CLUSTER_NAME}Client'" == .name)|.id')"
# if [ -z "${clientApplicationId}" ]; then
# clientApplicationId=$(az ad app create \
#                             --display-name "${CLUSTER_NAME}Client" \
#                             --native-app \
#                             --reply-urls "https://${CLUSTER_NAME}Client" \
#                             --query appId -o tsv)
# fi

# az ad sp list --all| jq '.[]|select( "'$clientApplicationId'" == .appId)' > /dev/null || \
# az ad sp create --id $clientApplicationId

# oAuthPermissionId=$(az ad app show --id $serverApplicationId --query "oauth2Permissions[0].id" -o tsv)

# az ad app permission add --id $clientApplicationId --api $serverApplicationId --api-permissions ${oAuthPermissionId}=Scope
# az ad app permission grant --id $clientApplicationId --api $serverApplicationId


# # setup network
# az network vnet create \
#                 --resource-group $RESOURCE_GROUP \
#                 --name "${RESOURCE_GROUP}_vnet" \
#                 --address-prefixes 192.168.0.0/16 \
#                 --subnet-name "${RESOURCE_GROUP}_subnet" \
#                 --subnet-prefix 192.168.1.0/24 \
#                 --subscription $SUBSCRIPTION_ID

# VNET_ID=$(az network vnet show \
#             --resource-group ${RESOURCE_GROUP} \
#             --name "${RESOURCE_GROUP}_vnet" --query id -o tsv \
#             --subscription $SUBSCRIPTION_ID)
# SUBNET_ID=$(az network vnet subnet show \
#             --resource-group ${RESOURCE_GROUP} \
#             --vnet-name "${RESOURCE_GROUP}_vnet" \
#             --name "${RESOURCE_GROUP}_subnet" \
#             --query id -o tsv \
#               --subscription $SUBSCRIPTION_ID)
# # permissions
# APP_ID=$(az ad app show --id $serverApplicationId --query "appId" -o tsv)
# az role assignment create --assignee $APP_ID --scope $VNET_ID --role "Network Contributor"


# az identity create --name "${CLUSTER_NAME}_id" --resource-group $RESOURCE_GROUP --subscription $SUBSCRIPTION_ID
# ASSIGN_ID=$(az identity list --query "[].{name:name, Id:id}"|jq -r '.[] | select(.name=="'${CLUSTER_NAME}_id'")|.Id')

# create identity
tenantId=$(az account show --query tenantId -o tsv)

# From https://github.com/Azure/azure-cli/issues/9585#issuecomment-502542000
credId="$(az ad app list| jq '[.[]| { name: .displayName, id: .appId}]' | jq -r '.[]|select("'${CLUSTER_NAME}AKS-sp'" == .name)|.id')"

# if the cluster exist, don't create a new id, just re-use the existing one
cluster_id="$(az aks list| jq -r '.[] | select("'${CLUSTER_NAME}'" == .name) | .id ')"
if [ -z "${cluster_id}" ]; then
    if [ ! -z "${credId}" ]; then
        az ad sp delete --id "${credId}"
    fi
    az ad sp create-for-rbac \
        --name "${CLUSTER_NAME}AKS-sp" \
        --skip-assignment > "${AD_SP_CREDS_JSON}"
    credId="$(az ad app list| jq '[.[]| { name: .displayName, id: .appId}]' | jq -r '.[]|select("'${CLUSTER_NAME}AKS-sp'" == .name)|.id')"
fi

# TODO: these are not being used but might be useful for us later when working with AAD managed clusters
# we're leaving it out for now.
# serverApplicationId="$(az ad app list| jq '[.[]| { name: .displayName, id: .appId}]' | jq -r '.[]|select("'${CLUSTER_NAME}Server'" == .name)|.id')"
# if [ -z "${serverApplicationId}" ]; then
# serverApplicationId=$(az ad app create \
#                         --display-name "${CLUSTER_NAME}Server" \
#                         --identifier-uris "https://${CLUSTER_NAME}Server" \
#                         --query appId -o tsv)
# fi
# echo "serverApplicaitonId ==> ${serverApplicationId}

#
# Autoscaler feature, only if you need the feature, aks-preview must be installed:
# Help: https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler
az extension add --name aks-preview

# create resource group
az group create --name $RESOURCE_GROUP \
                    --location $LOCATION \
                    --subscription $SUBSCRIPTION_ID

echo "create cluster"
    # --enable-managed-identity \
    # --assign-identity "$ASSIGN_ID" \
az aks create \
    -g "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}" \
    -s "${VM_SIZE}" \
    --node-count 1 \
    --min-count 1 \
    --max-count $NODE_COUNT \
    --load-balancer-sku $SKU_NAME \
    --generate-ssh-keys \
    --network-plugin azure \
    --service-principal "${credId}" \
    --client-secret "$(cat "${AD_SP_CREDS_JSON}" | jq -r '.password')" \
    --vm-set-type VirtualMachineScaleSets \
    --enable-cluster-autoscaler \
    --subscription "${SUBSCRIPTION_ID}"

# TODO: these are not being used but might be useful for us later when working with AAD managed clusters
    # --node-vm-size "${VM_SIZE}" \
    # --node-count "${NODE_COUNT}" \
    # --vm-set-type AvailabilitySet \
    # --no-ssh-key \
    # --aad-server-app-id "${serverApplicationId}" \
    # --aad-server-app-secret "${serverApplicationSecret}" \
    # --aad-client-app-id "${clientApplicationId}" \
    # --aad-tenant-id "${tenantId}" \
    # --network-plugin azure \
    # --vnet-subnet-id "${SUBNET_ID}" \
    # --docker-bridge-address 172.17.0.1/16 \
    # --dns-service-ip 10.2.0.10 \
    # --service-cidr 10.2.0.0/24 \
    # --service-principal msi \
    # --client-secret null \
    # --subscription "${SUBSCRIPTION_ID}"

echo "AKS version ==> $(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME \
                                --query "currentKubernetesVersion" \
                                --subscription $SUBSCRIPTION_ID)"

