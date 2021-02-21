## Introduction

This is quick step deployment for AKS.

## Steps
1. Login with `az login`
2. Build the containers with the command `./script/buildimages.sh`
3. Deploy each aks resource:
   ```
   kubectl apply -f ./config/aks/namespace.yaml
   kubectl apply -R -f ./config/aks/configmap
   kubectl apply -R -f ./config/aks/secrets
   kubectl apply -R -f ./config/aks/volumes
   kubectl apply -R -f ./config/aks/service
   kubectl apply -R -f ./config/aks/deployment
   ```
4. Check the deployments with commands (example, change the pod names):
   ``
   kubeclt --namespace human-connection get deployments
   kubeclt --namespace human-connection get pods
   kubeclt --namespace human-connection describe pod backend-d978bf44-vpj5k
   ```

