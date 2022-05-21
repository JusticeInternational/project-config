#!/usr/bin/env bash

set -e

export TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.${TARGET_ENV}

kubectl describe namespace ${NAMESPACE}-${TARGET_ENV} | grep "Name:.*${NAMESPACE}-${TARGET_ENV}" || (
  az login
  az account set -s "${SUBSCRIPTION_ID}"

  az aks get-credentials \
    --overwrite-existing \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --subscription $SUBSCRIPTION_ID
)
