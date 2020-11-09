#!/bin/bash

set -e
# bootstrap a new webapp
#
# usage: TENANT_ID={tenant id} SUBSCRIPTION_ID={subscription id} release.sh
set -x -v

ACR_NAME="${ACR_NAME:-redsol}"
ACR_REGISTRY="${ACR_NAME}.azurecr.io"
SERVICE_PRINCIPAL_NAME="${SERVICE_PRINCIPAL_NAME:-redsol-acr-sp}"
GITHUB_REGISTRY="${GITHUB_REGISTRY:-docker.pkg.github.com}"
GITHUB_ACTOR="${GITHUB_ACTOR:-$(whoami)}"
SERVICE_PRINCIPAL_NAME="${SERVICE_PRINCIPAL_NAME:-redsol-pull-acr-sp}"
REPOSITORY="${REPOSITORY:-justiceinternational/project-config}"

AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-redsol-rg}"
AZURE_WEBAPP_NAME="${AZURE_WEBAPP_NAME:-redsol-app}"

[ -z "${SUBSCRIPTION_ID}" ] && (2>&1 echo "Please setup your SUBSCRIPTION_ID environment variable" && exit 1)
[ -z "${TENANT_ID}" ] && (2>&1 echo "Please setup your TENANT_ID environment variable" && exit 1)
[ -z "${GITHUB_TOKEN}" ] && (2>&1 echo "Please setup your GITHUB_TOKEN environment variable" && exit 1)

# Login to docker registry
echo "${GITHUB_TOKEN}" | docker login "${GITHUB_REGISTRY}" --username "${GITHUB_ACTOR}" --password-stdin

# Get scope
ACR_SCOPE=$(az acr show \
        --name "${ACR_NAME}" \
        --query id --output tsv \
        --subscription "${SUBSCRIPTION_ID}")

# Assign Permisions for Private Registry
ACR_PASSWORD=$(az ad sp create-for-rbac \
                    --name "http://${SERVICE_PRINCIPAL_NAME}" \
                    --scopes "${ACR_SCOPE}" \
                    --role acrpull --query password --output tsv)
ACR_USERNAME=$(az ad sp show \
                    --id "http://${SERVICE_PRINCIPAL_NAME}" \
                    --query appId --output tsv)

# Login to ACR Registry
echo "${ACR_PASSWORD}" | docker login "${ACR_REGISTRY}" --username "${ACR_USERNAME}" --password-stdin

# Assign the desired role to the service principal. Modify the '--role' argument
# value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
az role assignment create --assignee "${ACR_USERNAME}" --scope "${ACR_SCOPE}" --role acrpull

# Tag
docker pull "${GITHUB_REGISTRY}/${REPOSITORY}/db:latest"
docker tag  "${GITHUB_REGISTRY}/${REPOSITORY}/db:latest" \
            "${ACR_REGISTRY}/db:latest"

# Push
docker push "${ACR_REGISTRY}/db:latest"

# Restart
az webapp restart --name "${AZURE_WEBAPP_NAME}" --resource-group "${AZURE_RESOURCE_GROUP}" --subscription "${SUBSCRIPTION_ID}"
echo "all done \o/"