#!/bin/bash
# Copy the canonical install-helpers.sh into each addon directory.
# Supervisor builds each addon with the addon dir as the Docker build context,
# so the helpers file must physically exist inside every addon dir.
set -euo pipefail
cd "$(dirname "$0")"
for addon in zwave-js-server zwave-js-ui; do
  cp install-helpers.sh "${addon}/install-helpers.sh"
done
echo "Synced install-helpers.sh into addon directories."
