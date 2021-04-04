#!/bin/bash

set -x -v

source ./script/env_source.sh

#
# Login account
az login
az account set -s "${SUBSCRIPTION_ID}"

az acr create -g $RESOURCE_GROUP --name $ACR_NAME \
              --sku Basic \
              --subscription $SUBSCRIPTION_ID

az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME \
            --attach-acr $ACR_NAME \
            --subscription $SUBSCRIPTION_ID