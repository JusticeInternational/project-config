#!/bin/bash

set -e
# use this script to bootstrap the ACR service principal
#
# usage: TENANT_ID={tenant id} SUBSCRIPTION_ID={subscription id} bootstrap-acr.sh

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
ACR_NAME="${ARC_NAME:-redsol}"
SERVICE_PRINCIPAL_NAME="${SERVICE_PRINCIPAL_NAME:-redsol-acr-sp}"

[ -z "${SUBSCRIPTION_ID}" ] && (2>&1 echo "Please setup your SUBSCRIPTION_ID environment variable" && exit 1)
[ -z "${TENANT_ID}" ] && (2>&1 echo "Please setup your TENANT_ID environment variable" && exit 1)

# Login
az login --tenant "${TENANT_ID}"

# Obtain the full registry ID for subsequent command args
ACR_REGISTRY_ID=$(az acr show --name "${ACR_NAME}" --query id --output tsv --subscription "${SUBSCRIPTION_ID}")

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
SP_PASSWD=$(az ad sp create-for-rbac --name http://$SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query password --output tsv)
SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

# Assign the desired role to the service principal. Modify the '--role' argument
# value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
az role assignment create --assignee "${SP_APP_ID}" --scope "${ACR_REGISTRY_ID}" --role acrpush

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"