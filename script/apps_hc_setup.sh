#!/bin/bash
#/ Usage: script/apps_hc_setup.sh
#/ calls on script/app_setup.sh to deploy more than one webapp
#/ for humman-connection
#
set -e

source ./script/env_source.sh

#/ set DOCKER_PAT as secret
# TODO: finish this setup and test it
RESOURCE_GROUP=rg-redsol \
APP_NAME=db \
ENVIRONMENT=production \
REPO_NAME=project-config \
ORG_NAME=justiceinternational \
WEBSITE_PORT=