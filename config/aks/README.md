## Introduction

This is quick step deployment for AKS.

## Steps
1. Login with `az login`
2. Build the containers with the command `./script/buildimages.sh`
3. Create the namespace:
   ```
   kubectl apply -f ./config/aks/namespace.yaml
   ```
3. Refresh [the password](/docs/references/kube_notes/bootstrap.md) :
   ```
   kubectl --namespace human-connection \
     create secret docker-registry acrregistrycreds \
       --docker-server="${ACR_REGISTRY}" \
       --docker-password="${AKS_DOCKER_PASSWORD}" \
       --docker-username="${AKS_DOCKER_USERNAME}"
   ```
3. Deploy each aks resource:
   ```
   kubectl apply -R -f ./config/aks/configmap && \
   kubectl apply -R -f ./config/aks/secrets && \
   kubectl apply -R -f ./config/aks/volumes && \
   kubectl apply -R -f ./config/aks/service && \
   kubectl apply -R -f ./config/aks/deployment
   ```
4. Check the deployments with commands (example, change the pod names):
   ``
   kubectl --namespace human-connection get deployments
   kubectl --namespace human-connection get pods
   kubectl --namespace human-connection describe pod backend-d978bf44-vpj5k
   ```

## Monitor

To get the ip addresses of the services:
```
kubectl --namespace human-connection get service backend --watch
kubectl --namespace human-connection get service neo4j --watch
```

## Cleanup
Run the command

```
kubectl delete namespace human-connection
```