#!/usr/bin/env bash

set -e

set -x -v

echo "Building ACR images"

HC_BRANCH="${HC_BRANCH:-origin/stable}"
ACR_REGISTRY="${ACR_REGISTRY:-redsolacr.azurecr.io}"
GHCR_REGISTRY="${GHCR_REGISTRY:-ghcr.io}"
ACR_REGISTRY_NAME="$(echo $ACR_REGISTRY|awk -F'.' '{print $1}')"
HC_DIR="${HC_DIR:-.env/Human-Connection}"
SERVICES="${SERVICES:-neo4j backend}"
PROJECT="${PROJECT:-humanconnection}"
VERSION="${VERSION:-latest}"
ORG_NAME="${ORG_NAME:-justiceinternational}"
REPO_NAME="${REPO_NAME:-project-config}"

# Get the Human Connection project
function git_clone_hc() {
    mkdir -p "${HC_DIR}"
    if [[ ! -d "${HC_DIR}/.git" ]]; then
        git clone https://github.com/JusticeInternational/Human-Connection "${HC_DIR}"
    fi
    # TODO lookup the default branch
    _default_branch="origin/stable"
    (
      cd "${HC_DIR}" && \
      git checkout "${_default_branch}"
      git reset --hard "${_default_branch}"
      git branch --list|grep -e "\s${HC_BRANCH}$" || git checkout -b "${HC_BRANCH}"
      git checkout "${HC_BRANCH}"
      eval git pull $(echo "${HC_BRANCH}" | sed 's/\// /')
    )
}

# build container
function build_container() {
    _service="${1}"
    docker-compose --file "${HC_DIR}/docker-compose.yml" build "${_service}"
    _source_service="${_service}"
    [[ "${_service}" = "backend" ]] && _source_service="nitro-${_service}"
    docker tag humanconnection/${_source_service}:${VERSION} "${ACR_REGISTRY}/${PROJECT}/${_service}:${VERSION}"
    docker tag humanconnection/${_source_service}:${VERSION} "${GHCR_REGISTRY}/${ORG_NAME}/${REPO_NAME}/${_service}:${VERSION}"
    docker tag humanconnection/${_source_service}:${VERSION} "${GHCR_REGISTRY}/${ORG_NAME}/${REPO_NAME}/${_service}:latest"
}

# push to registries
function push_container() {
   _service="${1}"
   az acr login -n "${ACR_REGISTRY_NAME}"
   docker push "${ACR_REGISTRY}/${PROJECT}/${_service}:${VERSION}"

   echo ${GITHUB_TOKEN} | docker login ghcr.io --username $(whoami) --password-stdin
   docker push "${GHCR_REGISTRY}/${ORG_NAME}/${REPO_NAME}/${_service}:${VERSION}"
   docker push "${GHCR_REGISTRY}/${ORG_NAME}/${REPO_NAME}/${_service}:latest"
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
