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

az acr import --name $REGISTRY_NAME --source $CERT_MANAGER_REGISTRY/$CERT_MANAGER_IMAGE_CONTROLLER:$CERT_MANAGER_TAG --image $CERT_MANAGER_IMAGE_CONTROLLER:$CERT_MANAGER_TAG || echo "warning skipping"
az acr import --name $REGISTRY_NAME --source $CERT_MANAGER_REGISTRY/$CERT_MANAGER_IMAGE_WEBHOOK:$CERT_MANAGER_TAG --image $CERT_MANAGER_IMAGE_WEBHOOK:$CERT_MANAGER_TAG || echo "warning skipping"
az acr import --name $REGISTRY_NAME --source $CERT_MANAGER_REGISTRY/$CERT_MANAGER_IMAGE_CAINJECTOR:$CERT_MANAGER_TAG --image $CERT_MANAGER_IMAGE_CAINJECTOR:$CERT_MANAGER_TAG || echo "warning skipping"



# get public ip already assigned to the cluster
MC_RESOURCE_GROUP=$(az aks show \
    --name "${CLUSTER_NAME}" \
    --resource-group  "${RESOURCE_GROUP}" \
    --output tsv \
    --query "nodeResourceGroup")

# create a public IP for AKS
# https://docs.microsoft.com/en-us/azure/aks/static-ip
az network public-ip create \
    --resource-group "${MC_RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}-ip" \
    --sku ${PUBLIC_IP_SKU_NAME} \
    --allocation-method Static \
    --subscription "${SUBSCRIPTION_ID}"

# Just informational for us
public_ip=$(az network public-ip show \
    --resource-group "${MC_RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}-ip" \
    --query ipAddress \
    --output tsv \
    --subscription "${SUBSCRIPTION_ID}")


kubectl create namespace $LB_NAMESPACE || echo "$LB_NAMESPACE already exists"

# this method doesn't seem to work anymore:
# helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
#   --namespace $LB_NAMESPACE \
#   --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$DNS_LABEL \
#   --set controller.service.loadBalancerIP=$public_ip
# so updating to using this method:
# https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/
# https://github.com/nginxinc/kubernetes-ingress/tree/v2.3.0/deployments/helm-chart
if [ ! -d ./kubernetes-ingress/.git ] ; then
  git clone https://github.com/nginxinc/kubernetes-ingress --branch v2.3.0
fi

# installation with manifest: https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/
# cd ./kubernetes-ingress/deployments
# 1.
# # Create a namespace and a service account for the Ingress Controller:
# kubectl apply -f common/ns-and-sa.yaml
# # Create a cluster role and cluster role binding for the service account:
# kubectl apply -f rbac/rbac.yaml
# # (App Protect only) Create the App Protect role and role binding:
# kubectl apply -f rbac/ap-rbac.yaml
# # (App Protect DoS only) Create the App Protect DoS role and role binding:
# kubectl apply -f rbac/apdos-rbac.yaml
# 2.
# # Create a secret with a TLS certificate and a key for the default server in NGINX:
# # kubectl apply -f common/default-server-secret.yaml
# # Note: The default server returns the Not Found page with the 404 status code for all requests for domains for which there are no Ingress rules defined. For testing purposes we include a self-signed certificate and key that we generated. However, we recommend that you use your own certificate and key.
# # Create a config map for customizing NGINX configuration:
# kubectl apply -f common/nginx-config.yaml
# # Create an IngressClass resource:
# kubectl apply -f common/ingress-class.yaml
# # Create custom resource definitions for VirtualServer and VirtualServerRoute, TransportServer and Policy resources:
# kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
# kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
# kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
# kubectl apply -f common/crds/k8s.nginx.org_policies.yaml
# # If you would like to use the TCP and UDP load balancing features of the Ingress Controller, create the following additional resources:
# # Create a custom resource definition for GlobalConfiguration resource:
# kubectl apply -f common/crds/k8s.nginx.org_globalconfigurations.yaml
# # Resources for NGINX App Protect
# # If you would like to use the App Protect module, create the following additional resources:
# # Create a custom resource definition for APPolicy, APLogConf and APUserSig:
# kubectl apply -f common/crds/appprotect.f5.com_aplogconfs.yaml
# kubectl apply -f common/crds/appprotect.f5.com_appolicies.yaml
# kubectl apply -f common/crds/appprotect.f5.com_apusersigs.yaml
# # Resources for NGINX App Protect DoS
# # If you would like to use the App Protect DoS module, create the following additional resources:
# # Create a custom resource definition for APDosPolicy, APDosLogConf and DosProtectedResource:
# kubectl apply -f common/crds/appprotectdos.f5.com_apdoslogconfs.yaml
# kubectl apply -f common/crds/appprotectdos.f5.com_apdospolicy.yaml
# kubectl apply -f common/crds/appprotectdos.f5.com_dosprotectedresources.yaml
# 3. deploy
# # run the Arbitrator by using a Deployment and Service
# kubectl apply -f deployment/appprotect-dos-arb.yaml
# kubectl apply -f service/appprotect-dos-arb-svc.yaml
# # For NGINX deployment, run:
# kubectl apply -f deployment/nginx-ingress.yaml
# # For NGINX daemon set, run:
# kubectl apply -f daemon-set/nginx-ingress.yaml
# # 4. Get Access to the Ingress Controller
# # option 1) Create a service with the type NodePort:
# kubectl create -f service/nodeport.yaml
# # option 2) For GCP or Azure, run:
# kubectl apply -f service/loadbalancer.yaml
# # Use the public IP of the load balancer to access the Ingress Controller. To get the public IP:
# # For GCP or Azure, run:
# kubectl get svc nginx-ingress --namespace=nginx-ingress




# helm installation
cd kubernetes-ingress/deployments/helm-chart

kubectl apply -f crds/
kubectl apply -n $LB_NAMESPACE -f crds/
helm upgrade nginx-ingress . \
  --namespace $LB_NAMESPACE \
  --set controller.replicaCount=1 \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
  --set controller.setAsDefaultIngress=true \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$DNS_LABEL \
  --set controller.service.loadBalancerIP=$public_ip ||
  helm install nginx-ingress . \
    --namespace $LB_NAMESPACE \
    --set controller.replicaCount=1 \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.setAsDefaultIngress=true \
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


# setup loadbalancer by deploying 1 app
./script/demo_app_public_lb.sh