#!/bin/sh
plugins_mark() {
  mkdir -p /data/plugins/.installed
  printf '%s\n' "$2" > "/data/plugins/.installed/$1"
}

plugins_marked() {
  [ -f "/data/plugins/.installed/$1" ]
}

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
