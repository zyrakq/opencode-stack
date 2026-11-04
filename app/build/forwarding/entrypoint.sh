#!/bin/sh
set -eu
mkdir -p /data/plugins/.installed
for marker in /data/plugins/.installed/*; do
  [ -f "$marker" ] || continue
  name="$(basename "$marker")"
  keep=""
  for token in ${PLUGINS:-}; do
    if [ "$token" = "$name" ]; then
      keep=1
    fi
  done
  if [ -z "$keep" ]; then
    rm -f "$marker"
  fi
done
for token in ${PLUGINS:-}; do
  if [ -f "/opt/plugins/install-$token.sh" ]; then
    sh "/opt/plugins/install-$token.sh" || echo "plugins: install failed: $token" >&2
  else
    echo "plugins: unknown plugin: $token" >&2
  fi
done
ARGS="--hostname ${OPENCODE_SERVE_HOSTNAME:-0.0.0.0} --port ${OPENCODE_SERVE_PORT:-4096}"
for origin in ${OPENCODE_CORS_ORIGIN:-}; do
  ARGS="$ARGS --cors $origin"
done
if [ -z "${OPENCODE_CONFIG_CONTENT:-}" ] && [ -d /data/plugins/.installed ]; then
  entries=""
  for marker in /data/plugins/.installed/*; do
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
