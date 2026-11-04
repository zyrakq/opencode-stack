#!/bin/sh
set -euo pipefail
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/common.sh"

plugins_marked micode && exit 0

MICODE_COMMIT=2469fea962ba2d5926e8172b237a72750e16688c
MICODE_URL="https://codeload.github.com/pjotrvv/micode/tar.gz/$MICODE_COMMIT"
TMP=/tmp/micode-install

rm -rf "$TMP"
mkdir -p "$TMP" /data/plugins
fetch_retry "$MICODE_URL" "$TMP/src.tar.gz"
tar -xzf "$TMP/src.tar.gz" -C "$TMP"

cp -r "$TMP/micode-$MICODE_COMMIT/v2-adapter" /data/plugins/micode-v2

if ! command -v npm >/dev/null 2>&1; then
  apk add --no-cache nodejs npm
fi
cd /data/plugins/micode-v2
npm install --omit=dev --no-audit --no-fund

rm -rf "$TMP"
plugins_mark micode "/data/plugins/micode-v2"
echo "plugins: micode installed at /data/plugins/micode-v2"
