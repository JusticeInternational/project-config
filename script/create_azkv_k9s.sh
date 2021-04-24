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
            --name "${CLUSTER_NAME}-kv" \
            --resource-group "${RESOURCE_GROUP}" \
            --location "${LOCATION}"

# setup https://github.com/Azure/secrets-store-csi-driver-provider-azure
helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts

helm install csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure

# check that everything is installed

kubectl get pods -l app=csi-secrets-store -n kube-system | grep csi-secrets-store
kubectl get pods -l app=csi-secrets-store-provider-azure | grep csi-secrets-store-provider-azure

echo "AZKV on K8s installed"