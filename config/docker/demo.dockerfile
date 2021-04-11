ARG DOCKER_REGISTRY
FROM ubuntu:bionic
RUN apt-get update -y && apt-get install -y curl net-tools

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

#
# install node
ENV NODE_VERSION=12.6.0
ENV NVM_DIR=/root/.nvm
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION} && \
    . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION} && \
    . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION} && \
    node --version && \
    npm --version

COPY ./config/docker/script/server.js /app/server.js
COPY ./config/docker/script/routes /app/routes
ADD ./config/docker/script/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    npm install fastify

ENV PORT 80
EXPOSE $PORT
ENTRYPOINT [ "/tini", "--" ]
CMD ["/app/entrypoint.sh"]
