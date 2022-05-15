#!/bin/bash

set -x -v

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh

az acr create -g $RESOURCE_GROUP --name $ACR_NAME \
              --sku Basic \
              --subscription $SUBSCRIPTION_ID

az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME \
            --attach-acr $ACR_NAME \
            --subscription $SUBSCRIPTION_ID