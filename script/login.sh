#!/usr/bin/env bash

set -e

export TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.${TARGET_ENV}

AZ_CLUSTER_NAME=$(az aks show \
    --name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP \
    --output tsv --query "name" \
    --subscription $SUBSCRIPTION_ID \
    || echo "")

if [ "$AZ_CLUSTER_NAME" != "${CLUSTER_NAME}" ]; then
  az login
  az account set -s "${SUBSCRIPTION_ID}"
fi

# set the current context and login
az aks get-credentials \
    --overwrite-existing \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --subscription $SUBSCRIPTION_ID
if ! kubectl get nodes > /dev/null 2>&1; then
  echo "No nodes found in the cluster.  failed to login, Exiting."
  exit 1
fi
