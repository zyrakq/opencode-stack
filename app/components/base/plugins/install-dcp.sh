#!/bin/sh
set -euo pipefail
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/common.sh"

plugins_marked dcp && exit 0

DCP_SPEC='@tarquinen/opencode-dcp@3.2.0'
DCP_NAME='@tarquinen/opencode-dcp'
DCP_VERSION='3.2.0'

TMP=/tmp/dcp-install
rm -rf "$TMP"
mkdir -p "$TMP"
fetch_retry "https://registry.npmjs.org/$DCP_NAME" "$TMP/meta.json"
grep -q "\"$DCP_VERSION\"" "$TMP/meta.json" || {
  echo "plugins: $DCP_SPEC not found on the npm registry" >&2
  exit 1
}
rm -rf "$TMP"

plugins_mark dcp "$DCP_SPEC"
echo "plugins: dcp pinned to $DCP_SPEC (installed by opencode at runtime)"
