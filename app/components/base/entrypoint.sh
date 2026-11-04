#!/bin/sh
# Baked entrypoint: translate env vars into `opencode serve` flags.
# Upstream serve accepts only --hostname/--port/--cors (repeatable) flags.
set -eu
ARGS="--hostname ${OPENCODE_SERVE_HOSTNAME:-0.0.0.0} --port ${OPENCODE_SERVE_PORT:-4096}"
for origin in ${OPENCODE_CORS_ORIGIN:-}; do
  ARGS="$ARGS --cors $origin"
done
exec opencode serve $ARGS
