#!/bin/sh
# headroom plugin: CLI-ONLY pip install. headroom-ai is installed --no-deps
# (its dependency group installs abort all-or-nothing on py3.14, so deps are
# staged: one batch, then one package at a time). NO plugin entry and NO
# marker in /opt/plugins/.installed — headroom needs a live proxy at
# 127.0.0.1:8787 which the serve container does not run; use
#   docker exec opencode-stack-app headroom ...
# Idempotency via `command -v headroom` (a marker would be injected by the
# entrypoint as a bogus plugin entry).
#
# Known-harmless warnings: pip-as-root notice; "requires ast-grep-cli"
# metadata warning (ast-grep-cli has no musl wheels; headroom falls back
# gracefully); magika is dropped (no py3.14 wheel; headroom lazy-imports it
# inside try/except).
set -euo pipefail
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/common.sh"

plugins_enabled PLUGINS_HEADROOM || exit 0
command -v headroom >/dev/null 2>&1 && exit 0

HEADROOM_VERSION=0.20.15

if ! command -v pip >/dev/null 2>&1; then
  apk add --no-cache python3 py3-pip
fi
PIP="pip install --no-cache-dir --break-system-packages"

# headroom itself, no deps.
$PIP "headroom-ai==$HEADROOM_VERSION" --no-deps

# Stage 1: core runtime deps (one group install).
$PIP click "litellm==1.82.3" opentelemetry-api pydantic rich tiktoken

# Stage 2: remaining deps, one at a time (a single group install aborts
# all-or-nothing on resolution conflicts).
for dep in opentelemetry-sdk fastapi uvicorn "httpx[http2]" watchdog websockets mcp zstandard openai; do
  $PIP "$dep"
done

headroom --version
echo "plugins: headroom CLI $HEADROOM_VERSION installed (no plugin entry; run via docker exec)"
