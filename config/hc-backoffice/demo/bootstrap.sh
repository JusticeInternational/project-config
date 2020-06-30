#!/bin/bash

set -e

# Lets setup the human connection backend for development

# setup docker-compose
if [ ! -x /usr/local/bin/docker-compose ]; then
  sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# setup ngrok https://dashboard.ngrok.com/get-started/setup
if [ ! -x /usr/local/bin/ngrok ]; then
    curl -L https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip > /tmp/ngrok.zip
    sudo unzip /tmp/ngrok.zip -d /usr/local/bin
    rm -f /tmp/ngrok.zip
    ngrok --version
fi

function get_username() {
  curl -X POST \
    -s -H "Content-Type: application/json" \
    --data '{ "query": "{User(role:admin){name}}"}' \
    http://localhost:4000/graphql | \
    jq '.data.User[0].name' 2>/dev/null
}

function is_backend_up() {
  [ ! -z "$(get_username)" ] && return 0
  return 1
}

docker-compose up -d

for i in $(seq 1 30); do
  is_backend_up && docker-compose exec backend yarn run db:seed && \
    break || sleep 5 && echo 'waiting for backend to start';
done

ngrok start -config ./ngrok.yml webapp
