#!/bin/bash
#
set -x -v

source ./script/env_source.sh

#
# Login account
az account list --query "[].{Name:name, User:user.name, IsDefault:isDefault, Id:id}" | jq -r '.[]|select( "'$SUBSCRIPTION_ID'" == .Id)' || \
  az login
az account set -s "${SUBSCRIPTION_ID}"

az acr build -t ${ACR_NAME}.azurecr.io/demo:latest \
             -r ${ACR_NAME} \
             -f ./config/docker/demo.dockerfile \
             --build-arg DOCKER_REGISTRY=${ACR_NAME}.azurecr.io .
kubectl apply -R -f ./config/k8s/demo