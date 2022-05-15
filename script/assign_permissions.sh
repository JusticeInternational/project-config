#!/bin/bash

set -x -v

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh

AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv --subscription $SUBSCRIPTION_ID) && \
APPDEV_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)&& \
az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster User Role" --scope $AKS_ID --subscription $SUBSCRIPTION_ID

AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv --subscription $SUBSCRIPTION_ID) && \
APPDEV_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)&& \
az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster Admin Role" --scope $AKS_ID --subscription $SUBSCRIPTION_ID

CURRENT_ID=$(az ad signed-in-user show --query userPrincipalName -o tsv)

GROUP_ID=$(az ad group show --group $APPDEV_NAME --query objectId -o tsv)
cat << EOF | kubectl apply -f -
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev-admin
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
# from ;  
- kind: Group
  namespace: default
  name: $GROUP_ID
- kind: User
  namespace: default
  name: $CURRENT_ID
EOF