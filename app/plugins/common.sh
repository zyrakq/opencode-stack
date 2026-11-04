# Shared helpers for the plugins install scripts (sourced, not executed).
# Runs inside the docker build (busybox ash); the base image provides busybox
# wget/tar/gzip/sha256sum but no curl/node/npm/git/python/pip/bun.

# plugins_enabled <VAR_NAME> — true when the toggle is set to any non-empty
# value except an explicit "false" (empty/unset = disabled).
plugins_enabled() {
  eval "plugins_enabled_val=\${$1:-}"
  [ -n "$plugins_enabled_val" ] && [ "$plugins_enabled_val" != "false" ]
}

# plugins_mark <name> <entry> — record a plugin as installed. The marker file
# content is the LITERAL plugin config entry (a baked dir path or an npm
# spec); the entrypoint concatenates markers into OPENCODE_CONFIG_CONTENT.
plugins_mark() {
  mkdir -p /opt/plugins/.installed
  printf '%s\n' "$2" > "/opt/plugins/.installed/$1"
}

# plugins_marked <name> — already installed?
plugins_marked() {
  [ -f "/opt/plugins/.installed/$1" ]
}

# fetch_retry <url> <outfile> [retries] — busybox wget with retries.
fetch_retry() {
  fetch_retry_url="$1"
  fetch_retry_out="$2"
  fetch_retry_tries="${3:-3}"
  fetch_retry_i=1
  while [ "$fetch_retry_i" -le "$fetch_retry_tries" ]; do
    if wget -q -T 30 -O "$fetch_retry_out" "$fetch_retry_url"; then
      return 0
    fi
    rm -f "$fetch_retry_out"
    fetch_retry_i=$((fetch_retry_i + 1))
    sleep 2
  done
  echo "plugins: fetch failed after $fetch_retry_tries attempts: $fetch_retry_url" >&2
  return 1
}
