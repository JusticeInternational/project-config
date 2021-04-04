ARG DOCKER_REGISTRY
FROM ubuntu:bionic
RUN apt-get update -y && apt-get install -y curl net-tools

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ADD ./config/docker/script/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV PORT 80
EXPOSE $PORT
ENTRYPOINT [ "/tini", "--" ]
CMD ["/app/entrypoint.sh"]
