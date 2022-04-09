#!/bin/bash
#/ Usage: script/app_setup.sh
#/ deploy webapp services app
#
set -e

#/ required envvars
export WEBSITE_PORT="${WEBSITE_PORT:-8080}"
export APP_NAME="${APP_NAME:-myApp}"
export AZ_REGION="${AZ_REGION:-eastus}"
export ENVIRONMENT="${ENVIRONMENT:-production}"
export SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
export RESOURCE_GROUP="${RESOURCE_GROUP:-rg-${APP_NAME}}"

# pricing https://azure.microsoft.com/en-us/pricing/details/app-service/linux/
export APP_SERVICE_PLAN="${APP_SERVICE_PLAN:-B2}"

#/ docker settings and image path
export DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
export REPO_NAME="${REPO_NAME:-}"
export ORG_NAME="${ORG_NAME:-}"
export GITHUB_SHA="${GITHUB_SHA:-latest}"
export DOCKER_IMAGE="${DOCKER_REGISTRY}/${ORG_NAME}/${REPO_NAME}/${APP_NAME}:${GITHUB_SHA}"
export DOCKER_USRERNAME="${DOCKER_USRERNAME:-$(whoami)}"
export DOCKER_PAT="${DOCKER_PAT:-${GITHUB_TOKEN}}"

echo "APP_NAME         => ${APP_NAME}"
echo "AZ_REGION        => ${AZ_REGION}"
echo "ENVIRONMENT      => ${ENVIRONMENT}"
echo "RESOURCE_GROUP   => ${RESOURCE_GROUP}"
echo "APP_SERVICE_PLAN => ${APP_SERVICE_PLAN}"
echo "DOCKER_IMAGE     => ${DOCKER_IMAGE}"
echo "WEBSITE_PORT     => ${WEBSITE_PORT}"

export CHECK_ENV_LIST="APP_NAME AZ_REGION ENVIRONMENT SUBSCRIPTION_ID REPO_NAME ORG_NAME DOCKER_PAT WEBSITE_PORT"
for cv in ${CHECK_ENV_LIST} ; do
    test ! -z "$(eval echo "\$${cv}")" || (
        echo ""
        echo "${cv} is not set, please set the environment value for ${cv} and try again."
        exit 1
    )
done

echo "Login to az"
az account show | az login --use-device-code
# TODO, if we could run this on MS managed service then we can use:
# az login --identity --output none

echo "Creating resource group => ${RESOURCE_GROUP}"
az group create \
   --name $RESOURCE_GROUP \
   --location $AZ_REGION \
   --subscription $SUBSCRIPTION_ID

echo "Creating app service plan => ${APP_SERVICE_PLAN}"
az appservice plan create \
   --resource-group $RESOURCE_GROUP \
   --name $APP_SERVICE_PLAN \
   --subscription $SUBSCRIPTION_ID \
   --is-linux

echo "Creating web app => ${APP_NAME}"
az webapp create \
    --name "${APP_NAME}-${ENVIRONMENT}" \
    --plan "${APP_SERVICE_PLAN}" \
    --resource-group "${RESOURCE_GROUP}" \
    --subscription "${SUBSCRIPTION_ID}" \
    --deployment-container-image-name "${DOCKER_IMAGE}"

echo "Configure AppSettings => ${APP_NAME}"
az webapp config appsettings set \
    --name "${APP_NAME}-${ENVIRONMENT}" \
    --resource-group "${RESOURCE_GROUP}" \
    --subscription "${SUBSCRIPTION_ID}" \
    --settings \
      DOCKER_REGISTRY_SERVER_URL=https://${DOCKER_REGISTRY} \
      DOCKER_REGISTRY_SERVER_USERNAME="${DOCKER_USRERNAME}" \
      DOCKER_REGISTRY_SERVER_PASSWORD="${DOCKER_PAT}"

echo "App Sepcific AppSettings => ${APP_NAME}"
az webapp config appsettings set \
    --name "${APP_NAME}-${ENVIRONMENT}" \
    --resource-group "${RESOURCE_GROUP}" \
    --subscription "${SUBSCRIPTION_ID}" \
    --settings \
      ENVIRONMENT="${ENVIRONMENT}" \
      WEBSITES_PORT="${WEBSITE_PORT}" \
      APP_SHA="$(git rev-parse HEAD)" \
      APP_REF="$(git rev-parse --abbrev-ref HEAD)"

echo "Setup Logging => ${APP_NAME}"
az webapp log config \
    --name "${APP_NAME}-${ENVIRONMENT}" \
    --resource-group "${RESOURCE_GROUP}" \
    --subscription "${SUBSCRIPTION_ID}" \
    --docker-container-logging filesystem

# TODO should we setup managed identity?
# az webapp identity assign --resource-group myResourceGroup --name <app-name> --query principalId --output tsv
# TODO should we setup api endpoint authorization
# TODO, how to deploy an image
# az webapp config container set \
#     --name "${APP_NAME}-${ENVIRONMNET}" \
#     --resource-group "${RESOURCE_GROUP}" \
#     --subscription "${SUBSCRIPTION_ID}" \
#     --docker-custom-image-name "${DOCKER_IMAGE}" \
#     --docker-registry-server-url https://${DOCKER_REGISTRY}

echo "view logs with the command: "
echo "az webapp log tail \\"
echo " --name ${APP_NAME}-${ENVIRONMENT} \\"
echo " --resource-group ${RESOURCE_GROUP} \\"
echo " --subscription ${SUBSCRIPTION_ID}"

curl "https://${APP_NAME}-${ENVIRONMENT}.azurewebsites.net"