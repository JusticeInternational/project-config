#!/usr/bin/env bash

set -e

set -x -v

echo "Building ACR images"

ACR_REGISTRY="${ACR_REGISTRY:-redsolacr.azurecr.io}"
ACR_REGISTRY_NAME="$(echo $ACR_REGISTRY|awk -F'.' '{print $1}')"
HC_DIR="${HC_DIR:-.env/Humman-Connection}"
SERVICES="${SERVICES:-neo4j backend}"
PROJECT="${PROJECT:-humanconnection}"
VERSION="${VERSION:-latest}"

# Get the Human Connection project
function git_clone_hc() {
    mkdir -p "${HC_DIR}"
    if [[ ! -d "${HC_DIR}/.git" ]]; then
        git clone https://github.com/JusticeInternational/Human-Connection "${HC_DIR}"
    else
        # TODO lookup the default branch
        (cd "${HC_DIR}" && git reset --hard origin/stable && git pull origin stable)
    fi
}

# build container
function build_container() {
    _service="${1}"
    docker-compose --file "${HC_DIR}/docker-compose.yml" build "${_service}"
    _source_service="${_service}"
    [[ "${_service}" = "backend" ]] && _source_service="nitro-${_service}"
    docker tag humanconnection/${_source_service}:${VERSION} "${ACR_REGISTRY}/${PROJECT}/${_service}:${VERSION}"
}

# push to ACR
function push_container() {
   _service="${1}"
   az acr login -n "${ACR_REGISTRY_NAME}"
   docker push "${ACR_REGISTRY}/${PROJECT}/${_service}:${VERSION}"
}

TARGET="${TARGET:-}"
git_clone_hc
if [[ -z "${TARGET}" ]]; then
    for _service in $SERVICES; do
        echo "Building ${_service}"
        build_container "${_service}"
        push_container "${_service}"
    done
else
    echo "Building ${TARGET}"
    build_container "${TARGET}"
    push_container "${_service}"
fi