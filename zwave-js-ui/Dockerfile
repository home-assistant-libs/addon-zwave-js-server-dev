FROM node:22

ENV NODE_OPTIONS=--max-old-space-size=8192 \
    STORE_DIR=/data/store

# Create app directory
WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get -y install curl unzip jq git && \
    corepack enable

EXPOSE 8091 3000

ADD run.sh /
ADD install-helpers.sh /

ENTRYPOINT [ "/run.sh" ]
