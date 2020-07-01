FROM node:lts-slim as base
LABEL Description="Development Container for RedSol" Vendor="JusticeInternational" Version="0.0.1" Maintainer="wenlock@github.com"

EXPOSE 4000

RUN apt-get update && \
    apt-get install -y \
    zsh \
    vim \
    jq
