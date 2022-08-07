#!/bin/bash
#
# A demo app per https://docs.microsoft.com/en-us/azure/aks/ingress-basic
# note, broken images
set -x -v
set -e

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV

./script/login.sh

# https://medium.com/microsoftazure/aks-different-load-balancing-options-for-a-single-cluster-when-to-use-what-abd2c22c2825
# demos creating a public load balancer without nginx ingress controller
kubectl create namespace hello-world3 || echo "hello-world3 already exists"

cat << EOF | kubectl apply --namespace hello-world3 -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: hello-world3
  name: aks-helloworld-three  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld-three
  template:
    metadata:
      labels:
        app: aks-helloworld-three
    spec:
      containers:
      - name: aks-helloworld-three
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
          name: http
        env:
        - name: TITLE
          value: "Hello World 3 - Welcome to Azure Kubernetes Service (AKS)"
---
apiVersion: v1
kind: Service
metadata:
  namespace: hello-world3
  name: aks-helloworld-three  
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: aks-helloworld-three
EOF

