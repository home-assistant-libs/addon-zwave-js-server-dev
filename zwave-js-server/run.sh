#!/bin/bash

source /install-helpers.sh

DEFAULT_SERVER_REPO="zwave-js/zwave-js-server"
DEFAULT_ZWAVE_JS_REPO="zwave-js/node-zwave-js"
APP_DIR=/usr/src/app

# Fail loudly (set before the option reads so a missing/corrupt options.json
# aborts instead of silently resolving to empty specs = npm latest).
set -euo pipefail

SERIAL_PORT=$(jq -r '.serial_port' /data/options.json)
SERVER_SOURCE=$(jq -r '.zwave_js_server_branch_or_commit // ""' /data/options.json)
ZWAVE_JS_SOURCE=$(jq -r '.zwave_js_branch_or_commit // ""' /data/options.json)

if [[ -z "$SERVER_SOURCE" ]]; then
  echo "ERROR: zwave_js_server_branch_or_commit may not be empty" >&2
  exit 1
fi

cd "$APP_DIR"
# Start clean: overrides from a previous boot of this container must not
# survive into a boot that no longer requests them (Supervisor restarts
# reuse the same container filesystem).
rm -f "$APP_DIR/package.json" "$APP_DIR/package-lock.json"
ensure_package_json "$APP_DIR"

echo "Installing @zwave-js/server from '${SERVER_SOURCE}'..."
if is_git_ref "$SERVER_SOURCE"; then
  parse_git_ref "$SERVER_SOURCE" "$DEFAULT_SERVER_REPO"
  npm install "${REPO}#${REF}"
else
  npm install "@zwave-js/server@${SERVER_SOURCE}"
fi

if [[ -n "$ZWAVE_JS_SOURCE" ]]; then
  if is_git_ref "$ZWAVE_JS_SOURCE"; then
    parse_git_ref "$ZWAVE_JS_SOURCE" "$DEFAULT_ZWAVE_JS_REPO"
    override_zwave_js_from_monorepo "$APP_DIR" "$REPO" "$REF"
  else
    override_package "$APP_DIR" "zwave-js" "$ZWAVE_JS_SOURCE"
  fi
fi

log_resolved_versions "$APP_DIR" "@zwave-js/server" "zwave-js"

echo "Start Z-Wave JS Server using $SERIAL_PORT"
exec ./node_modules/.bin/zwave-server "$SERIAL_PORT" --config /data/options.json
