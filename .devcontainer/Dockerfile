FROM node:lts-slim as base
LABEL Description="Development Container for RedSol" Vendor="JusticeInternational" Version="0.0.1" Maintainer="wenlock@github.com"

# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=node
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Docker script args, location, and expected SHA - SHA generated on release
ARG DOCKER_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/docker-debian.sh"
ARG DOCKER_SCRIPT_SHA="dev-mode"
ARG ENABLE_NONROOT_DOCKER="true"
ARG SOURCE_SOCKET=/var/run/docker-host.sock
ARG TARGET_SOCKET=/var/run/docker.sock

EXPOSE 4000

COPY containeruser.sh /bin/containeruser.sh
COPY entrypoint.sh /bin/entrypoint.sh

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y install --no-install-recommends \
       apt-transport-https \    
       apt-utils \
       dialog \
       ca-certificates \
       coreutils \
       curl \
       git \
       gnupg2 \
       iproute2 \
       jq \
       less \
       lsb-release \
       openssh-client \
       procps \
       socat \
       sudo \
       vim \
       bash \
       zsh \
    && chmod +x /bin/entrypoint.sh \
    && chmod +x /bin/containeruser.sh \
    && /bin/containeruser.sh \
    # Use Docker script from script library to set things up (installs: docker, docker-compose, sets up dind, and a bunch of other stuff)
    && curl -sSL $DOCKER_SCRIPT_SOURCE -o /tmp/docker-setup.sh \
    && ([ "${DOCKER_SCRIPT_SHA}" = "dev-mode" ] || (echo "${DOCKER_SCRIPT_SHA} */tmp/docker-setup.sh" | sha256sum -c -)) \
    && /bin/bash /tmp/docker-setup.sh "${ENABLE_NONROOT_DOCKER}" "${SOURCE_SOCKET}" "${TARGET_SOCKET}" "${USERNAME}" \
    && rm /tmp/docker-setup.sh \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# try running as root
# USER $USERNAME

ENTRYPOINT "/bin/entrypoint.sh"
CMD [ "sleep", "infinity" ]
