#!/bin/bash

set -x -v
set -e

source ./script/env_source.sh

#
# Create and setup Azure KeyVault for Kubernetes

#
# Login account
az login
az account set -s "${SUBSCRIPTION_ID}"
az aks get-credentials \
            --resource-group $RESOURCE_GROUP \
            --name $CLUSTER_NAME \
            --subscription $SUBSCRIPTION_ID \
            --admin

az keyvault create \
            --name "${KEYVAULT_NAME}" \
            --resource-group "${RESOURCE_GROUP}" \
            --location "${LOCATION}"

# setup identity permissions
VMSS_RG_NAME=$(echo "mc_${RESOURCE_GROUP}_${CLUSTER_NAME}_${LOCATION}" | tr '[:upper:]' '[:lower:]')
VMSS_NAME=$(az vmss list --resource-group ${VMSS_RG_NAME} --subscription $SUBSCRIPTION_ID|jq -r '.[].name')

IDENTITY_JSON=$(az identity create -g $RESOURCE_GROUP -n $USER_ASSIGNED_ID_NAME)
USER_ASSIGNED_ID=$(echo $IDENTITY_JSON|jq -r '.id')
USER_ASSIGNED_CLIENTID=$(echo $IDENTITY_JSON|jq -r '.clientId')

az vmss identity assign -g $VMSS_RG_NAME -n $VMSS_NAME --identities $USER_ASSIGNED_ID

# set policy to access keys in your Keyvault
az keyvault set-policy -n $KEYVAULT_NAME \
                       --key-permissions get \
                       --spn $USER_ASSIGNED_CLIENTID
# set policy to access secrets in your Keyvault
az keyvault set-policy -n $KEYVAULT_NAME \
                       --secret-permissions get \
                       --spn $USER_ASSIGNED_CLIENTID
# set policy to access certs in your Keyvault
az keyvault set-policy -n $KEYVAULT_NAME \
                       --certificate-permissions get \
                       --spn $USER_ASSIGNED_CLIENTID

# setup https://github.com/Azure/secrets-store-csi-driver-provider-azure
helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts

[[ "$(helm -n kube-system history csi -o json|jq -r '.[].status')" = "deployed" ]] || \
helm install --namespace kube-system csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure

# check that everything is installed
kubectl -n kube-system get pods|grep csi-secrets-store

echo "AZKV on K8s installed"