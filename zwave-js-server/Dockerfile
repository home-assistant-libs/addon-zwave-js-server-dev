FROM node:16

# Create app directory
WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get -y install curl unzip jq && \
    npm install -g typescript && \
    npm install -g ts-node

EXPOSE 3000

ADD run.sh /

ENTRYPOINT [ "/run.sh" ]