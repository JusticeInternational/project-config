# Introduction

We'll have project automation, actions and general scripts in this location.

## Building docker demo app

```
az acr build -t redsolacr.azurecr.io/demo:latest -r redsolacr -f ./config/docker/demo.dockerfile --build-arg DOCKER_REGISTRY=redsolacr.azurecr.io .
```

## Depoly demo app

```
kubectl delete namespace demo-app && kubectl apply -R -f ./config/k8s/demo
```