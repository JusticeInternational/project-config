#!/bin/bash

set -e

# Lets setup the human connection backend for development

# setup docker-compose
[ ! -x /usr/local/bin/docker-compose ] && \
  sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# setup ngrok https://dashboard.ngrok.com/get-started/setup
if [ ! -x /usr/local/bin/ngrok ]; then
    curl -L https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip > /tmp/ngrok.zip
    sudo unzip /tmp/ngrok.zip -d /usr/local/bin
    rm -f /tmp/ngrok.zip
    ngrok --version
fi

docker-compose up -d

ngrok start -config ./ngrok.yml webapp
