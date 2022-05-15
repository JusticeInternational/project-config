#!/bin/bash
#
set -x -v
set -e

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh

az acr build -t ${ACR_NAME}.azurecr.io/demo:latest \
             -r ${ACR_NAME} \
             -f ./config/docker/demo.dockerfile \
             --build-arg DOCKER_REGISTRY=${ACR_NAME}.azurecr.io .
kubectl apply -R -f ./config/k8s/demo