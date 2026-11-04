#!/bin/sh
# micode plugin: fetch the upstream repo tarball at a pinned commit, copy the
# prebuilt v2-adapter package standalone into /opt/plugins/micode-v2, and
# install its npm dependencies (node/npm are added here; the base image has
# none). The plugin entry is the baked dir path — opencode resolves the
# conventional index (v2-adapter ships index.js at the package root).
set -euo pipefail
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/common.sh"

plugins_enabled PLUGINS_MICODE || exit 0
plugins_marked micode && exit 0

# Pinned upstream commit (pjotrvv/micode, fix(mindmodel): load a manifest-less
# .mindmodel, and match on headings).
MICODE_COMMIT=2469fea962ba2d5926e8172b237a72750e16688c
MICODE_URL="https://codeload.github.com/pjotrvv/micode/tar.gz/$MICODE_COMMIT"
TMP=/tmp/micode-install

rm -rf "$TMP"
mkdir -p "$TMP" /opt/plugins
fetch_retry "$MICODE_URL" "$TMP/src.tar.gz"
tar -xzf "$TMP/src.tar.gz" -C "$TMP"

# Standalone copy: only the prebuilt v2-adapter package (lib/ + index.js +
# package.json are committed upstream; no build step needed).
cp -r "$TMP/micode-$MICODE_COMMIT/v2-adapter" /opt/plugins/micode-v2

# npm install (NOT bun — bun is not in the base image and the deps must be
# baked, not auto-installed at runtime).
if ! command -v npm >/dev/null 2>&1; then
  apk add --no-cache nodejs npm
fi
cd /opt/plugins/micode-v2
npm install --omit=dev --no-audit --no-fund

rm -rf "$TMP"
plugins_mark micode "/opt/plugins/micode-v2"
echo "plugins: micode installed at /opt/plugins/micode-v2"
