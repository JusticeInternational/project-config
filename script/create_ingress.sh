#!/bin/bash

set -x -v

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh

# create a public IP for AKS
# https://docs.microsoft.com/en-us/azure/aks/static-ip
az network public-ip create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${RESOURCE_NAME}-${TARGET_ENV}-ip" \
    --sku $SKU_NAME \
    --allocation-method static

public_ip=$(az network public-ip show --resource-group "${RESOURCE_GROUP}" --name "${RESOURCE_NAME}-${TARGET_ENV}-ip" --query ipAddress --output tsv)

# todo setup tls; https://docs.microsoft.com/en-us/azure/aks/ingress-static-ip?tabs=azure-cli

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --version 4.0.13 \
    --namespace ingress-basic --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.service.loadBalancerIP=$STATIC_IP \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$NAMESPACE-new \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux

kubectl --namespace ingress-basic get services -o wide -w nginx-ingress-ingress-nginx-controller
