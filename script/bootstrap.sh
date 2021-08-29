#!/bin/bash

set -e
# bootstrap a new webapp
#
# usage: TENANT_ID={tenant id} SUBSCRIPTION_ID={subscription id} bootstrap.sh

AZURE_LOCATION="${AZURE_LOCATION:-East US}"
AZURE_APP_PLAN="${AZURE_APP_PLAN:-redsol-plan}"
AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-redsol-rg}"
AZURE_WEBAPP_NAME="${AZURE_WEBAPP_NAME:-redsol-app}"
ACR_NAME="${ACR_NAME:-redsol}"
ACR_URL="https://${ACR_NAME}.azurecr.io"
SERVICE_PRINCIPAL_NAME="${SERVICE_PRINCIPAL_NAME:-redsol-pull-acr-sp}"

[ -z "${SUBSCRIPTION_ID}" ] && (2>&1 echo "Please setup your SUBSCRIPTION_ID environment variable" && exit 1)
[ -z "${TENANT_ID}" ] && (2>&1 echo "Please setup your TENANT_ID environment variable" && exit 1)

# Login
az login --tenant "${TENANT_ID}"

# Create the location and plan
az group create --location "${AZURE_LOCATION}" --name "${AZURE_RESOURCE_GROUP}" --subscription "${SUBSCRIPTION_ID}"
az appservice plan create \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --name "${AZURE_APP_PLAN}" \
    --is-linux --sku B1 \
    --subscription "${SUBSCRIPTION_ID}"

# Create the web app
az webapp create \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --plan "${AZURE_APP_PLAN}" \
    --name "${AZURE_WEBAPP_NAME}" \
    --multicontainer-config-type compose \
    --multicontainer-config-file config/docker-compose.yml \
    --subscription "${SUBSCRIPTION_ID}"

# Create the registry
az acr create \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --name "${ACR_NAME}" \
    --sku Basic --admin-enabled true \
    --subscription "${SUBSCRIPTION_ID}"

# Create the identity
P_ID=$(az webapp identity assign \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --name "${AZURE_WEBAPP_NAME}" \
        --query principalId \
        --subscription "${SUBSCRIPTION_ID}" --output tsv)
ACR_SCOPE=$(az acr show \
        --name "${ACR_NAME}" \
        --query id --output tsv \
        --subscription "${SUBSCRIPTION_ID}")
az role assignment create \
    --assignee "${P_ID}" \
    --scope "${ACR_SCOPE}" \
    --role acrpull

# Assign Permisions for Private Registry
ACR_PASSWORD=$(az ad sp create-for-rbac \
                    --name "http://${SERVICE_PRINCIPAL_NAME}" \
                    --scopes "${ACR_SCOPE}" \
                    --role acrpull --query password --output tsv)
ACR_USERNAME=$(az ad sp show \
                    --id "http://${SERVICE_PRINCIPAL_NAME}" \
                    --query appId --output tsv)

az role assignment create --assignee "${ACR_USERNAME}" --scope "${ACR_SCOPE}" --role acrpull

az webapp config container set \
    --docker-registry-server-password "${ACR_PASSWORD}" \
    --docker-registry-server-url "${ACR_URL}" \
    --docker-registry-server-user "${ACR_USERNAME}" \
    --name "${AZURE_WEBAPP_NAME}" \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --subscription "${SUBSCRIPTION_ID}"

echo "all done \o/"