#!/bin/bash

set -x -v -e

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh

# Setp w/ TLS: https://docs.microsoft.com/en-us/azure/aks/ingress-tls?tabs=azure-cli

# Import the cert-manager images used by the Helm chart into your ACR
REGISTRY_NAME=${ACR_NAME}
CERT_MANAGER_REGISTRY=quay.io
CERT_MANAGER_TAG=v1.8.0
CERT_MANAGER_IMAGE_CONTROLLER=jetstack/cert-manager-controller
CERT_MANAGER_IMAGE_WEBHOOK=jetstack/cert-manager-webhook
CERT_MANAGER_IMAGE_CAINJECTOR=jetstack/cert-manager-cainjector

az acr import --name $REGISTRY_NAME --source $CERT_MANAGER_REGISTRY/$CERT_MANAGER_IMAGE_CONTROLLER:$CERT_MANAGER_TAG --image $CERT_MANAGER_IMAGE_CONTROLLER:$CERT_MANAGER_TAG
az acr import --name $REGISTRY_NAME --source $CERT_MANAGER_REGISTRY/$CERT_MANAGER_IMAGE_WEBHOOK:$CERT_MANAGER_TAG --image $CERT_MANAGER_IMAGE_WEBHOOK:$CERT_MANAGER_TAG
az acr import --name $REGISTRY_NAME --source $CERT_MANAGER_REGISTRY/$CERT_MANAGER_IMAGE_CAINJECTOR:$CERT_MANAGER_TAG --image $CERT_MANAGER_IMAGE_CAINJECTOR:$CERT_MANAGER_TAG


# create a public IP for AKS
# https://docs.microsoft.com/en-us/azure/aks/static-ip
az network public-ip create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}-ip" \
    --sku ${PUBLIC_IP_SKU_NAME} \
    --allocation-method Static \
    --subscription "${SUBSCRIPTION_ID}"

# Just informational for us
public_ip=$(az network public-ip show \
   --resource-group "${RESOURCE_GROUP}" \
   --name "${CLUSTER_NAME}-ip" \
   --query ipAddress --output tsv --subscription "${SUBSCRIPTION_ID}")

kubectl create namespace $LB_NAMESPACE || echo "$LB_NAMESPACE already exists"

# this method doesn't seem to work anymore:
# helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
#   --namespace $LB_NAMESPACE \
#   --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$DNS_LABEL \
#   --set controller.service.loadBalancerIP=$public_ip
# so updating to using this method:
# https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/
# https://github.com/nginxinc/kubernetes-ingress/tree/v2.3.0/deployments/helm-chart
git clone https://github.com/nginxinc/kubernetes-ingress --branch v2.3.0
cd kubernetes-ingress/deployments/helm-chart
kubectl apply -f crds/
kubectl apply -n $LB_NAMESPACE -f crds/
helm upgrade nginx-ingress . \
  --namespace $LB_NAMESPACE \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$DNS_LABEL \
  --set controller.service.loadBalancerIP=$public_ip ||
  helm install nginx-ingress . \
    --namespace $LB_NAMESPACE \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$DNS_LABEL \
    --set controller.service.loadBalancerIP=$public_ip 

kubectl get pods -n $LB_NAMESPACE

# custom domain
# az network dns record-set a add-record \
#     --resource-group myResourceGroup \
#     --zone-name MY_CUSTOM_DOMAIN \
#     --record-set-name "*" \
#     --ipv4-address MY_EXTERNAL_IP

# install cert manager

# # Label the ingress-basic namespace to disable resource validation
# kubectl label namespace $LB_NAMESPACE cert-manager.io/disable-validation=true

# # Add the Jetstack Helm repository
# helm repo add jetstack https://charts.jetstack.io

# # Update your local Helm chart repository cache
# helm repo update

# Install the cert-manager Helm chart
# setup https://cert-manager.io/docs/concepts/issuer/ ClusterIssuer
# helm install cert-manager jetstack/cert-manager \
#   --namespace $LB_NAMESPACE \
#   --version $CERT_MANAGER_TAG \
#   --set installCRDs=true \
#   --set nodeSelector."kubernetes\.io/os"=linux \
#   --set image.repository=$ACR_URL/$CERT_MANAGER_IMAGE_CONTROLLER \
#   --set image.tag=$CERT_MANAGER_TAG \
#   --set webhook.image.repository=$ACR_URL/$CERT_MANAGER_IMAGE_WEBHOOK \
#   --set webhook.image.tag=$CERT_MANAGER_TAG \
#   --set cainjector.image.repository=$ACR_URL/$CERT_MANAGER_IMAGE_CAINJECTOR \
#   --set cainjector.image.tag=$CERT_MANAGER_TAG


# cat > /tmp/cluster-issuer.yaml <<EOF
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt
# spec:
#   acme:
#     server: https://acme-v02.api.letsencrypt.org/directory
#     email: MY_EMAIL_ADDRESS
#     privateKeySecretRef:
#       name: letsencrypt
#     solvers:
#     - http01:
#         ingress:
#           class: nginx
#           podTemplate:
#             spec:
#               nodeSelector:
#                 "kubernetes.io/os": linux
# EOF
# kubectl apply -f /tmp/cluster-issuer.yaml

