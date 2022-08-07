#!/usr/bin/env bash

set -e

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV
./script/login.sh

NAMESPACE=human-connection

# TODO: helm deployment
helm version --template "{{.Version}}" || (
    echo "Failed to run 'helm version'"
    echo "Install helm ; https://helm.sh/docs/intro/install/"
    exit 1
)

if [ -n "$(kubectl get namespace human-connection-dev 2>/dev/null)" ]; then
    helm upgrade \
        --set deployment.env="${TARGET_ENV}" \
        --set deployment.namespace="${NAMESPACE}" \
        hc ./config/k8s/hc
else
    helm install \
        --set deployment.env="${TARGET_ENV}" \
        --set deployment.namespace="${NAMESPACE}" \
        hc ./config/k8s/hc
fi