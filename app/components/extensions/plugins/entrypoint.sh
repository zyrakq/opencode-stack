#!/bin/sh
# Baked entrypoint (plugins extension): base serve-flag translation plus
# marker-driven plugin injection. Markers under /opt/plugins/.installed hold
# the LITERAL plugin config entry (baked dir path or npm spec); they are
# concatenated into OPENCODE_CONFIG_CONTENT — upstream v2.2.5 parses it as an
# additional virtual config doc (packages/core/src/config.ts,
# server-process.ts). Never writes to the persistent config volume
# /data/config; skips injection when OPENCODE_CONFIG_CONTENT is already set.
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
