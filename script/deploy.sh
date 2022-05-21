#!/usr/bin/env bash

set -e

TARGET_ENV="${TARGET_ENV:-dev}"
source ./.env.$TARGET_ENV
./script/login.sh


# TODO: helm deployment
helm version --template "{{.Version}}" || (
    echo "Failed to run 'helm version'"
    echo "Install helm ; https://helm.sh/docs/intro/install/"
    exit 1
)

helm upgrade --set deployment.env="${TARGET_ENV}" hc ./config/k8s/hc