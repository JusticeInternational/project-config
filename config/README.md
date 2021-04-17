# Introduction

We'll have project automation, actions and general scripts in this location.

Connect to backend API - `http://redsol.eastus.cloudapp.azure.com/`
## Building docker demo app

```
az acr build -t redsolacr.azurecr.io/demo:latest -r redsolacr -f ./config/docker/demo.dockerfile --build-arg DOCKER_REGISTRY=redsolacr.azurecr.io .
```

## Depoly demo app

```
kubectl delete namespace demo-app && kubectl apply -R -f ./config/k8s/demo
```

## Notes

These are just some general notes that will work with the following alias;

```
alias k='kubectl --namespace human-connection'
```

### Connecting to the ports for development
	- Let you open browser; http://localhost:7474/browser/
    - API : http://localhost:4000/graphql

```
k port-forward service/neo4j 7474:7474 7687:7687
k port-forward service/backend 4000:4000
```

### Connect over terminal

```
k exec --stdin --tty backend-7568bcd55-nzg94 -- /bin/bash
```

### Installing troubleshooting tools on neo4j

```
apt-get update && \
apt-get install -y \
    vim \
    curl \
    procps \
    net-tools \
    wget \
    jq \
    htop \
    iputils-ping \
    netcat
```

### Installing troubleshooting tools on backend

```
apk update && \
apk add \
    wget \
    vim \
    curl \
    procps \
    net-tools \
    wget \
    jq \
    htop \
    iputils \
    netcat-openbsd
```

### Testing pod to pod communication from backend

```
nc neo4j.human-connection.svc.cluster.local 7474
```
type `HELO` in connection

