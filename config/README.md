# Introduction

We'll have project automation, actions and general scripts in this location.

Connect to backend API - [http://redsol.eastus.cloudapp.azure.com/](http://redsol.eastus.cloudapp.azure.com/)

## Building docker demo app

```
az acr build \
             -t redsolacr.azurecr.io/demo:latest \
             -r redsolacr \
             -f ./config/docker/demo.dockerfile \
             --build-arg DOCKER_REGISTRY=redsolacr.azurecr.io \
             .
```

## Depoly demo app

```
kubectl delete namespace demo-app && \
  kubectl apply -R -f ./config/k8s/demo
```

## Notes

These are just some general notes that will work with the following alias;

```
alias k='kubectl --namespace human-connection'
```
### Login to k8s cluster
Clone the `project-config` repo and `cd ./project-config`.

```
source ./script/env_source.sh
az login
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --subscription $SUBSCRIPTION_ID
```

### Connecting to the ports for development
- Let you open browser; http://localhost:7474/browser/
- API : http://localhost:4000/graphql

Run these two commands in two seperate terminal windows.

Terminal 1:
```
k port-forward service/neo4j 7474:7474 7687:7687
```

Terminal 2:
```
k port-forward service/backend 4000:4000
```
These commands will remain running unitl you cancel them with `ctrl-c`. They are intended to open up local ports for you to access the graphql backend urls with `localhost`.

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

### Seed the database

This step should help with seeding the db for AKS cluster. 

1. Open a `bash` terminal and clone the `JusticeInternational/Human-Connection` repo or run `/script/buildimages.sh`. The `buildimages.sh` script will clone the repo to the `.env/Human-Connection` folder.
   ```
   git clone https://github.com/JusticeInternational/Human-Connection ./.env/Human-Connection
   ```
1. Make sure your logged into the target AKS cluster:
   ```
   source ./script/env_source.sh
   az login
   az aks get-credentials --resource-group $RESOURCE_GROUP \
                          --name $CLUSTER_NAME \
                          --overwrite-existing \
                          --subscription $SUBSCRIPTION_ID
   ```
   If you run the following commands you should see the running pods:
   ```
   ❯ kubectl --namespace human-connection get pods
   NAME                      READY   STATUS    RESTARTS   AGE
   backend-7568bcd55-d6zz2   1/1     Running   0          24h
   neo4j-664544488-6lhdz     1/1     Running   0          24h
   ```

1. Proxy the connection to AKS neo4j app:
   ```
   alias k='kubectl --namespace human-connection'
   k port-forward service/neo4j 7474:7474 7687:7687
   ```
   You should see output as follows:
   ```
   Forwarding from 127.0.0.1:7474 -> 7474
   Forwarding from [::1]:7474 -> 7474
   Forwarding from 127.0.0.1:7687 -> 7687
   Forwarding from [::1]:7687 -> 7687
   ```

1. Open a new `bash` terminal and setup the env. Copy the `.env.template` file to `.env`:
   
   ```
   cd ./.env/Human-Connection/backend
   cp .env.template .env
   ```

   Check the username and password configured in [`/config/k8s/hc/secrets/hc.yaml`](/config/k8s/hc/secrets/hc.yaml), for production we'll be setting this up in Az KeyVault.


   ```
   export NEO4J_USERNAME='<value from data.NEO4J_USERNAME>'
   export NEO4J_PASSWORD='<value from data.NEO4J_PASSWORD>'
   sed -i -e 's/NEO4J_USERNAME=.*/NEO4J_USERNAME='${NEO4J_USERNAME}'/' ./.env
   sed -i -e 's/NEO4J_PASSWORD=.*/NEO4J_PASSWORD='${NEO4J_PASSWORD}'/' ./.env
   ```

1. You should have yarn and node setup for the next step. Run the command:
   ```
   cd ./backend
   yarn install
   yarn db:seed
   ```
   You should see output as follows:
   ```
   ❯ yarn db:seed
   yarn run v1.22.10
   $ babel-node src/db/seed.js
   Warning: Email middleware will not try to send mails.
   Warning: Sentry middleware inactive.
   Seeded Data...
   ✨  Done in 52.35s.
   ```
1. You should now be able to browse the db at http://localhost:7474/browser/


### Test the API
We can test the API with `bash` and `curl` against the public dev url: `http://redsol.eastus.cloudapp.azure.com/`. Note this step will not require `kubectl port-forward` commands or an `az login`.

1. Open a `bash` terminal session and run the following scripts to give some helper functions:
   ```
   function graphql() {
    query="${1}"
    query="$(echo $query|tr -d '\n')"
    curl -X POST \
      -s -H "Content-Type: application/json" \
      --data "{ \"query\": \"${query}\"}" \
      ${CLIENT_API}/graphql
   }
   function graphql_schema() {
    graphql "query IntrospectionQuery {  __schema { types { name } } }" |jq -r
   }
   ```
1. Setup `CLIENT_API` with `export CLIENT_API=http://redsol.eastus.cloudapp.azure.com`
1. Try some commands:
   - Query the schema with [introspection](https://graphql.org/learn/introspection/), this requires `DEBUG=true` or `NODE_ENV=true`:
     ```
     graphql_schema
     ```
   - Query for admin users
     ```
     graphql "{User(role:admin){name}}" | jq -r '.data.User[]'
     ```
   - Query for categories
     ```
     graphql "{Category{id,name}}"| jq -r '.data' 
     ```
   - Query for service category
     ```
     graphql "{ServiceCategory{id,name}}"| jq -r '.data'
     ```
   - Query for service
     ```
     graphql "{Service{id,name}}"| jq -r '.data'
     ```





