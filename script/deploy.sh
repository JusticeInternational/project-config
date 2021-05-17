#!/usr/bin/env bash

set -e

source ./script/env_source.sh

export TARGET_ENV="${TARGET_ENV:-}"
# TODO: login code

# TODO: helm deployment
helm version --template "{{.Version}}" || (
    echo "Failed to run 'helm version'"
    echo "Install helm ; https://helm.sh/docs/intro/install/"
    exit 1
)

helm upgrade --set deployment.env="${TARGET_ENV}" hc ./config/k8s/hc