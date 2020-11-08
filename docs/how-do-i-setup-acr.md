## Setting up the Azure Container Registry (ACR)

Since we're deploying with ACR, we'll need to have a service [principle](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal) configured after we deploy the app.

### Pre-Req
- Make sure you've deployed the app at least once, and the redsol.azurecr.io exist

### Creating the Principle
- Run this script to create the id
  ```
  #!/bin/bash

    # Modify for your environment.
    # ACR_NAME: The name of your Azure Container Registry
    # SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
    ACR_NAME=redsol
    SERVICE_PRINCIPAL_NAME=redsol-acr-sp

    # Obtain the full registry ID for subsequent command args
    ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

    # Create the service principal with rights scoped to the registry.
    # Default permissions are for docker pull access. Modify the '--role'
    # argument value as desired:
    # acrpull:     pull only
    # acrpush:     push and pull
    # owner:       push, pull, and assign roles
    SP_PASSWD=$(az ad sp create-for-rbac --name http://$SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query password --output tsv)
    SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

    # Output the service principal's credentials; use these in your services and
    # applications to authenticate to the container registry.
    echo "Service principal ID: $SP_APP_ID"
    echo "Service principal password: $SP_PASSWD"
  ```
- Take note of the `SP_APP_ID` and the `SP_PASSWORD` and configure the `github/project-config` secrets with the new `ACR_USERNAME` with `SP_APP_ID` value and `ACR_PASSWORD` with `SP_PASSWORD` value.
- Finally assign the permisions to the registry for the service principle by running this script;
  ```
  #!/bin/bash

    # Modify for your environment. The ACR_NAME is the name of your Azure Container
    # Registry, and the SERVICE_PRINCIPAL_ID is the service principal's 'appId' or
    # one of its 'servicePrincipalNames' values.
    ACR_NAME=redsol
    SERVICE_PRINCIPAL_NAME=redsol-acr-sp

    # Populate value required for subsequent command args
    ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

    # Assign the desired role to the service principal. Modify the '--role' argument
    # value as desired:
    # acrpull:     pull only
    # acrpush:     push and pull
    # owner:       push, pull, and assign roles
    az role assignment create --assignee $SERVICE_PRINCIPAL_ID --scope $ACR_REGISTRY_ID --role acrpush
  ```
- That's it try out a new deployment :tada: