## Introduction

This is quick step deployment for AKS. If the cluster has not been shared or you have not been setup with a `dev` group access, you can also deploy a personell cluster with a free acount for about $50 / month with [these steps](/docs/references/kube_notes/bootstrap.md).

Note you may have to make updates locally to `/script/env_source.sh` if you are making a personell instance and then follow the [bootstrap guide](/docs/kube_notes/bootstrap.md).

## Steps

1. Login with `az login`
2. Build the containers with the command `./script/buildimages.sh`
3. Create the namespace:
   ```
   kubectl apply -R -f ./config/k8s/hc
   ```
4. Check the deployments with commands (example, change the pod names):
   ```
   kubectl --namespace human-connection get deployments
   kubectl --namespace human-connection get pods
   kubectl --namespace human-connection describe pod backend-d978bf44-vpj5k
   ```

   More notes can be found in [k8s docs here](/config/k8s/README.md).

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