## Introduction

This is quick step deployment for AKS. If the cluster has not been shared or you have not been setup with a `dev` group access, you can also deploy a personell cluster with a free acount for about $50 / month with [these steps](/docs/references/kube_notes/bootstrap.md).

Note you may have to make updates locally to `/.env.dev` if you are making a personell instance and then follow the [bootstrap guide](/docs/kube_notes/bootstrap.md).

All of these commands require that you have cloned the `JusticeInternational/project-config` repo:
```
cd /workspaces
git clone https://github.com/JusticeInternational/project-config
cd /workspaces/project-config
```

## Pre-Req

You should have each of these tools installed and setup:

1. [Install Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt), in codespaces:
   ```
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```
2. [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/), in codespaces:
   ```
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo mv ./kubectl /usr/local/bin/kubectl
   sudo chmod +x /usr/local/bin/kubectl
   ```
3. [Install helm](https://helm.sh/docs/intro/install/), in codespaces:
   ```
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   sudo chmod +x /usr/local/bin/helm
   ```

## Steps

1. Login to k8s env
   - Visit and login to [the portal](https://portal.azure.com/#@redsol.onmicrosoft.com/resource/subscriptions/8b91797a-2975-47ad-95dd-5767ebf67c90/resourceGroups/redsol-RG/providers/Microsoft.ContainerService/managedClusters/redsol/overview)
   - Login with the cli: `az login`
   - Get kubectl credentials: `source ./.env.dev && az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --subscription $SUBSCRIPTION_ID`
2. Build the containers for the branch you want with the command `HC_BRANCH=origin/yourbranch_name ./script/buildimages.sh`, Leave `HC_BRANCH` empty if to default to `origin/stable`.
3. Clean out any previous deployments: `kubectl delete namespace human-connection`
   WARNING THIS DELETES ALL DATA!!!
3. Run the deployment script:
   ```
   ./script/deploy.sh
   ```
4. Check the deployments with commands (example, change the pod names):
   ```
   kubectl --namespace human-connection get deployments
   kubectl --namespace human-connection get pods
   kubectl --namespace human-connection describe pod backend-d978bf44-vpj5k
   ```

   More notes can be found in [k8s docs here](/config/k8s/README.md).
5. [Follow additional instructions on resetting and updating the DB](https://github.com/JusticeInternational/project-config/blob/stable/config/README.md#building-redsol-backend-and-db).
## Monitor

To get the ip addresses of the services:
```
kubectl --namespace human-connection get service backend --watch
kubectl --namespace human-connection get service neo4j --watch
```

## Cleanup

Run the command to remove the app:

```
helm uninstall hc ./config/k8s/hc
kubectl delete namespace human-connection
```
