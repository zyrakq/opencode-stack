#!/bin/sh
# Baked entrypoint: translate env vars into `opencode serve` flags.
# Upstream serve accepts only --hostname/--port/--cors (repeatable) flags.
# Plugin injection (inert unless the plugins extension baked markers under
# /opt/plugins/.installed): marker contents are concatenated into
# OPENCODE_CONFIG_CONTENT (virtual config doc, upstream v2.2.5
# packages/core/src/config.ts) — never written to the persistent config
# volume /data/config; skipped when OPENCODE_CONFIG_CONTENT is already set.
set -eu
ARGS="--hostname ${OPENCODE_SERVE_HOSTNAME:-0.0.0.0} --port ${OPENCODE_SERVE_PORT:-4096}"
for origin in ${OPENCODE_CORS_ORIGIN:-}; do
  ARGS="$ARGS --cors $origin"
done
if [ -z "${OPENCODE_CONFIG_CONTENT:-}" ] && [ -d /opt/plugins/.installed ]; then
  entries=""
  for marker in /opt/plugins/.installed/*; do
    [ -f "$marker" ] || continue
    entry="$(cat "$marker")"
    [ -n "$entry" ] || continue
    [ -z "$entries" ] || entries="$entries, "
    entries="$entries\"$entry\""
  done
  if [ -n "$entries" ]; then
    export OPENCODE_CONFIG_CONTENT="{\"plugins\": [$entries]}"
  fi
fi
exec opencode serve $ARGS
