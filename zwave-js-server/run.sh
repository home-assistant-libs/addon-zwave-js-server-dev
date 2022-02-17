#!/bin/bash

SERIAL_PORT=$(cat /data/options.json | jq -r '.serial_port')
SERVER_SOURCE=$(cat /data/options.json | jq -r '.branch_or_commit')

cd /usr/src/app
echo "Fetching latest server version from $SERVER_SOURCE..."
npm install ${SERVER_SOURCE}

echo "Start Z-Wave Js Server using $SERIAL_PORT"
exec ./node_modules/.bin/zwave-server "$SERIAL_PORT" --config /data/options.json   
