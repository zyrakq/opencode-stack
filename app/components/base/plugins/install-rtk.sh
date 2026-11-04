#!/bin/sh
set -euo pipefail
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/common.sh"

if plugins_marked rtk && [ -x /usr/local/bin/rtk ]; then
  exit 0
fi

RTK_VERSION=1.1.0
RTK_TAG_COMMIT=753a3b0e939f2e4490fc24e3a1984010f40a103c
RTK_ASSET="rtk-x86_64-unknown-linux-musl.tar.gz"
RTK_SHA256=9454ad1b9489daa57ab0a9f4ebe2faaf4dc82b8a0f26c9e5135151abd7c9378d
RTK_URL="https://github.com/rtk-ai/rtk/releases/download/v$RTK_VERSION/$RTK_ASSET"
TMP=/tmp/rtk-install

rm -rf "$TMP"
mkdir -p "$TMP" /data/plugins/rtk
fetch_retry "$RTK_URL" "$TMP/$RTK_ASSET"
echo "$RTK_SHA256  $TMP/$RTK_ASSET" | sha256sum -c -
tar -xzf "$TMP/$RTK_ASSET" -C "$TMP"

install -m 0755 "$TMP/rtk" /usr/local/bin/rtk
rtk --version

rtk init -g --opencode >/dev/null 2>&1 || rtk init -g --opencode
[ -f /root/.config/opencode/plugins/rtk.ts ] || {
  echo "plugins: rtk init did not generate the opencode plugin shim" >&2
  exit 1
}
cp /root/.config/opencode/plugins/rtk.ts /data/plugins/rtk/index.ts

rm -rf "$TMP"
plugins_mark rtk "/data/plugins/rtk"
echo "plugins: rtk $RTK_VERSION installed (binary + /data/plugins/rtk/index.ts)"
