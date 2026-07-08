#!/bin/bash
# =============================================================================
# SYNCED FILE — the canonical copy lives at the repository root.
# Edit the root copy and run ./sync-helpers.sh; never edit addon-dir copies.
# =============================================================================
#
# Shared version-resolution helpers for the Z-Wave JS dev addons.
#
# Ref grammar for every *_branch_or_commit option:
#   ""             -> no override / skip (caller checks for empty)
#   "1.2.3"/"beta" -> npm version or dist-tag (no '#')
#   "owner/repo#ref" or "#ref" -> git ref; bare "#ref" uses the caller-supplied
#                                 default repo

# True if the value denotes a git ref rather than an npm version/dist-tag.
is_git_ref() {
  [[ "$1" == *"#"* ]]
}

# Split "owner/repo#ref" (or "#ref" + default repo) into REPO and REF globals.
parse_git_ref() {
  local value="$1" default_repo="$2"
  REPO="${value%%#*}"
  REF="${value#*#}"
  if [[ -z "$REPO" ]]; then
    REPO="$default_repo"
  fi
  if [[ -z "$REF" ]]; then
    echo "ERROR: '$value' has no ref after '#'" >&2
    return 1
  fi
  if [[ "$REF" == -* ]]; then
    echo "ERROR: ref '$REF' may not start with '-'" >&2
    return 1
  fi
}

# Ensure APP_DIR has a package.json; npm pkg set (overrides) requires one, and
# `npm install <pkg>` in a bare directory does not create it.
ensure_package_json() {
  local app_dir="$1"
  if [[ ! -f "$app_dir/package.json" ]]; then
    (cd "$app_dir" && npm init -y >/dev/null)
  fi
}

# Record an override for PKG in APP_DIR's package.json without installing.
# npm refuses an override that conflicts with a direct dependency, so when PKG
# is also a direct dependency we pin the dependency to the same spec.
# Note: pkg names containing '.' would be misparsed by npm pkg set's dotted-path syntax; fine for zwave-js/@zwave-js/* names.
_set_override() {
  local app_dir="$1" pkg="$2" spec="$3"
  (cd "$app_dir" \
    && npm pkg set "overrides.${pkg}=${spec}" \
    && if [[ "$(npm pkg get "dependencies.${pkg}")" != "{}" ]]; then
         npm pkg set "dependencies.${pkg}=${spec}"
       fi \
    && if [[ "$(npm pkg get "devDependencies.${pkg}")" != "{}" ]]; then
         npm pkg set "devDependencies.${pkg}=${spec}"
       fi)
}

# Override PKG everywhere in APP_DIR's tree and reinstall.
# SPEC is any npm spec: version, dist-tag, git+https URL, or file: path.
# A plain `npm install pkg@spec` would only replace the hoisted copy and npm
# would nest a stale duplicate under any parent whose semver range conflicts;
# `overrides` force every instance.
override_package() {
  local app_dir="$1" pkg="$2" spec="$3"
  echo "Overriding ${pkg} -> ${spec}"
  ensure_package_json "$app_dir"
  _set_override "$app_dir" "$pkg" "$spec"
  (cd "$app_dir" && npm install)
}

# Build zwave-js and all @zwave-js/* siblings from a node-zwave-js monorepo
# ref, then override them all in APP_DIR via file: tarballs.
# The siblings must come from the same ref: a branch that changes
# @zwave-js/core needs that branch's core, not the registry's.
override_zwave_js_from_monorepo() {
  local app_dir="$1" repo="$2" ref="$3"
  local src=/tmp/node-zwave-js tarball_dir=/tmp/zjs-tarballs

  rm -rf "$src" "$tarball_dir"
  # Pre-create the scope subdir: the pack --out pattern below contains the
  # scoped package name (with '/') and yarn does not create directories.
  mkdir -p "$tarball_dir/@zwave-js"

  echo "Cloning ${repo}#${ref}..."
  git clone --filter=blob:none "https://github.com/${repo}.git" "$src"
  git -C "$src" checkout "$ref"

  echo "Building node-zwave-js monorepo (this can take several minutes)..."
  (cd "$src" \
    && yarn install \
    && yarn build \
    && yarn workspaces foreach --all --no-private pack --out "${tarball_dir}/%s.tgz")

  # yarn pack rewrote workspace:* deps to concrete versions inside each
  # tarball; the overrides make every @zwave-js/* package in the app tree
  # resolve from the branch tarballs instead of the npm registry.
  ensure_package_json "$app_dir"
  local tarballs tarball name
  tarballs=$(find "$tarball_dir" -name '*.tgz')
  if [[ -z "$tarballs" ]]; then
    echo "ERROR: yarn pack produced no tarballs in ${tarball_dir}" >&2
    return 1
  fi
  while IFS= read -r tarball; do
    name=$(tar -xOzf "$tarball" package/package.json | jq -r '.name')
    _set_override "$app_dir" "$name" "file:${tarball}"
  done <<< "$tarballs"
  (cd "$app_dir" && npm install)
}

# Print PKG's version as resolved from APP_DIR ("NOT INSTALLED" if absent).
# Reads package.json files directly: `require('<pkg>/package.json')` is blocked
# by the "exports" field in modern packages.
resolved_version() {
  local app_dir="$1" pkg="$2"
  if [[ -f "$app_dir/node_modules/$pkg/package.json" ]]; then
    jq -r '.version // "unknown"' "$app_dir/node_modules/$pkg/package.json"
  elif [[ -f "$app_dir/package.json" \
      && "$(jq -r '.name' "$app_dir/package.json")" == "$pkg" ]]; then
    # APP_DIR itself is the package (git-cloned parent app)
    jq -r '.version // "unknown"' "$app_dir/package.json"
  else
    echo "NOT INSTALLED"
  fi
}

log_resolved_versions() {
  local app_dir="$1"; shift
  local pkg
  echo "=========== Resolved package versions ==========="
  for pkg in "$@"; do
    echo "  ${pkg}: $(resolved_version "$app_dir" "$pkg")"
  done
  echo "=================================================="
}
