# Z-Wave JS Development Add-ons

⚠️ These add-ons are not designed for production use and should only be used for development purposes. Any version of the stack can be installed, including broken/unreleased ones. ⚠️

## Installation

Adding this add-ons repository to your Home Assistant supervisor is
pretty easy. Follow [the official instructions][third-party-addons] on the
website of Home Assistant, and use the following URL:

```txt
https://github.com/home-assistant-libs/addon-zwave-js-server-dev
```

## Add-ons provided by this repository

### [Z-Wave JS Server](zwave-js-server)

Runs a headless `zwave-js-server` WebSocket server (port 3000) built from source. Useful for developing and testing new features for `zwave-js-server` and `zwave-js`.

Z-Wave settings (serial port, security keys, logging, storage) are configured directly via add-on options.

**Options:**

- `zwave_js_server_branch_or_commit` (default `zwave-js/zwave-js-server#master`) — version of `zwave-js-server` to install. See [Version options](#version-options).
- `zwave_js_branch_or_commit` (default `""`) — override for the `zwave-js` version `zwave-js-server` depends on. See [Version options](#version-options).
- `serial_port`, `securityKeys`, `logConfig`, `storage`, `presets` — passed through to `zwave-js-server` as usual.

**Before first start:** current `zwave-js-server` master rejects empty `securityKeys` at config load. Replace the default empty-string keys in the add-on's `securityKeys` options with real 32-hex-character keys before starting it for the first time.

**Note on v0.0.19:** the option `branch_or_commit` was renamed to `zwave_js_server_branch_or_commit`, and a new `zwave_js_branch_or_commit` option was added. If you're updating from an earlier version, re-save your configuration.

### [Z-Wave JS UI](zwave-js-ui)

Runs `zwave-js-ui` (formerly ZwaveJS2MQTT) built from source, exposing its web UI (port 8091) and its underlying `zwave-js-server` WebSocket server (port 3000). Useful for developing and testing new features across the `zwave-js-ui`, `zwave-js-server`, and `zwave-js` stack.

Z-Wave settings (serial port, security keys, etc.) are configured through the `zwave-js-ui` web UI rather than through add-on options, and are persisted under `/data/store`.

**Options:**

- `zwave_js_ui_branch_or_commit` (default `zwave-js/zwave-js-ui#master`) — version of `zwave-js-ui` to install. See [Version options](#version-options).
- `zwave_js_server_branch_or_commit` (default `""`) — override for the `zwave-js-server` version `zwave-js-ui` depends on. See [Version options](#version-options).
- `zwave_js_branch_or_commit` (default `""`) — override for the `zwave-js` version. See [Version options](#version-options).

### Port conflicts

Both add-ons map host port 3000 (the `zwave-js-server` WebSocket port) by default. They cannot run at the same time unless one add-on's port mapping is changed.

## Version options

Every `*_branch_or_commit` option shares the same grammar:

- `""` (empty) — only valid for override options (not the addon's primary package option): use whatever version the parent package pins as its dependency.
- An npm version or dist-tag, with no `#`, e.g. `15.25.2`, `latest`, `beta` — installed via a fast `npm install`.
- `owner/repo#ref` or bare `#ref` (uses that option's default repo) — a git branch, tag, or commit SHA. Default repos:
  - `zwave_js_ui_branch_or_commit` → `zwave-js/zwave-js-ui`
  - `zwave_js_server_branch_or_commit` → `zwave-js/zwave-js-server`
  - `zwave_js_branch_or_commit` → `zwave-js/node-zwave-js`

Installing a `zwave-js` git ref builds the entire `node-zwave-js` monorepo inside the container (`yarn` + TypeScript build), which adds several minutes to that boot. All installs happen at add-on start, so changing a version option only requires restarting the add-on — no image rebuild needed.

## Contributing

This is an active open-source project. Feel free to use the code and/or contribute changes.

Both add-ons ship a copy of `install-helpers.sh` with the shared version-resolution logic. These copies are synced from the canonical copy at the repository root via `./sync-helpers.sh`. Always edit the root copy and re-run the sync script — never edit the copies inside `zwave-js-server/` or `zwave-js-ui/` directly.

[third-party-addons]: https://home-assistant.io/hassio/installing_third_party_addons/
