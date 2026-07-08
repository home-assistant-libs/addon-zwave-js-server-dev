#!/bin/bash

source /install-helpers.sh

DEFAULT_UI_REPO="zwave-js/zwave-js-ui"
DEFAULT_SERVER_REPO="zwave-js/zwave-js-server"
DEFAULT_ZWAVE_JS_REPO="zwave-js/node-zwave-js"

UI_SOURCE=$(jq -r '.zwave_js_ui_branch_or_commit' /data/options.json)
SERVER_SOURCE=$(jq -r '.zwave_js_server_branch_or_commit // ""' /data/options.json)
ZWAVE_JS_SOURCE=$(jq -r '.zwave_js_branch_or_commit // ""' /data/options.json)

# Fail loudly: a failed install must not silently start on pinned versions.
set -euo pipefail

mkdir -p "$STORE_DIR"

if is_git_ref "$UI_SOURCE"; then
  parse_git_ref "$UI_SOURCE" "$DEFAULT_UI_REPO"
  APP_DIR=/usr/src/app/zwave-js-ui
  echo "Building zwave-js-ui from ${REPO}#${REF} (this can take several minutes)..."
  rm -rf "$APP_DIR"
  git clone "https://github.com/${REPO}.git" "$APP_DIR"
  git -C "$APP_DIR" checkout "$REF"
  (cd "$APP_DIR" && npm install && npm run build)
  START_CMD=(node server/bin/www.js)
else
  APP_DIR=/usr/src/app
  echo "Installing zwave-js-ui@${UI_SOURCE} from npm..."
  ensure_package_json "$APP_DIR"
  (cd "$APP_DIR" && npm install "zwave-js-ui@${UI_SOURCE}")
  START_CMD=(./node_modules/.bin/zwave-js-ui)
fi

if [[ -n "$SERVER_SOURCE" ]]; then
  if is_git_ref "$SERVER_SOURCE"; then
    parse_git_ref "$SERVER_SOURCE" "$DEFAULT_SERVER_REPO"
    override_package "$APP_DIR" "@zwave-js/server" "git+https://github.com/${REPO}.git#${REF}"
  else
    override_package "$APP_DIR" "@zwave-js/server" "$SERVER_SOURCE"
  fi
fi

if [[ -n "$ZWAVE_JS_SOURCE" ]]; then
  if is_git_ref "$ZWAVE_JS_SOURCE"; then
    parse_git_ref "$ZWAVE_JS_SOURCE" "$DEFAULT_ZWAVE_JS_REPO"
    override_zwave_js_from_monorepo "$APP_DIR" "$REPO" "$REF"
  else
    override_package "$APP_DIR" "zwave-js" "$ZWAVE_JS_SOURCE"
  fi
fi

log_resolved_versions "$APP_DIR" "zwave-js-ui" "@zwave-js/server" "zwave-js"

echo "Starting Z-Wave JS UI (web UI on :8091, WS server on :3000)..."
cd "$APP_DIR"
exec "${START_CMD[@]}"
