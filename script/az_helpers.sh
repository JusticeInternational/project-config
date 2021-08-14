#!/bin/bash

set -e

#
# Login account
# requires env_source.sh
function login_az() {

    az login
    az account set -s "${SUBSCRIPTION_ID}"

    az aks get-credentials \
                --resource-group "${RESOURCE_GROUP}" \
                --name "${CLUSTER_NAME}" \
                --subscription "${SUBSCRIPTION_ID}" \
                --admin

    az keyvault create \
                --name "${KEYVAULT_NAME}" \
                --resource-group "${RESOURCE_GROUP}" \
                --location "${LOCATION}"

}

#
# save secret

function az_save_secret() {
    _secret_name="${1}"
    _secret_val="${2}"

    echo "Saving secret for ${_secret_name}"
    az keyvault secret set \
        --vault-name "${KEYVAULT_NAME}" \
        --name "${_secret_name}" \
        --value "${_secret_val}" | jq '.attributes.updated' 

}