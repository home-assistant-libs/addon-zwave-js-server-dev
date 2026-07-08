FROM node:22

ENV NODE_OPTIONS=--max-old-space-size=8192

# Create app directory
WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get -y install --no-install-recommends curl unzip jq git && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g typescript && \
    npm install -g ts-node && \
    corepack enable

EXPOSE 3000

ADD run.sh /
ADD install-helpers.sh /

ENTRYPOINT [ "/run.sh" ]
