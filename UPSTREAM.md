# Upstream Provenance

## app — https://github.com/anomalyco/opencode

| date | upstream commit | image tag / digest | note |
|------|-----------------|--------------------|------|
| 2026-11-04 | tag `v2.2.5` | ghcr.io/anomalyco/opencode:2.2.5 (published, FROM-layer via dockerfile_inline) | initial dockerization: single `opencode` service (`opencode serve` + bundled web UI), XDG roots + config dir baked into the FROM-layer, entrypoint wrapper for serve flags |

## plugins extension — per-plugin upstreams

| plugin | source | pin |
|--------|--------|-----|
| micode | git tarball `https://codeload.github.com/pjotrvv/micode/tar.gz/<sha>` (branch `v2-adapter`) | commit `2469fea962ba2d5926e8172b237a72750e16688c` |
| dcp | npm registry `@tarquinen/opencode-dcp` | `3.2.0` |
| rtk | GitHub release `https://github.com/rtk-ai/rtk/releases/download/v1.1.0/rtk-x86_64-unknown-linux-musl.tar.gz` (sha256-pinned) | tag commit `753a3b0e939f2e4490fc24e3a1984010f40a103c` |
| headroom | PyPI `headroom-ai` | `0.20.15` |
