#!/bin/sh
set -euo pipefail
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/common.sh"

command -v headroom >/dev/null 2>&1 && exit 0

HEADROOM_VERSION=0.20.15

if ! command -v pip >/dev/null 2>&1; then
  apk add --no-cache python3 py3-pip
fi
PIP="pip install --no-cache-dir --break-system-packages"

$PIP "headroom-ai==$HEADROOM_VERSION" --no-deps

$PIP click "litellm==1.82.3" opentelemetry-api pydantic rich tiktoken

for dep in opentelemetry-sdk fastapi uvicorn "httpx[http2]" watchdog websockets mcp zstandard openai; do
  $PIP "$dep"
done

headroom --version
echo "plugins: headroom CLI $HEADROOM_VERSION installed (no plugin entry; run via docker exec)"
