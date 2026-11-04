# Upstream Provenance

## app — https://github.com/anomalyco/opencode

| date | upstream commit | image tag / digest | note |
|------|-----------------|--------------------|------|
| 2026-11-04 | tag `v2.2.5` | ghcr.io/anomalyco/opencode:2.2.5 (published, FROM-layer via dockerfile_inline) | initial dockerization: single `opencode-stack-app` service (`opencode serve` + bundled web UI), XDG roots + config dir baked into the FROM-layer, entrypoint wrapper for serve flags |
