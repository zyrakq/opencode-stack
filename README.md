# 🤖 OpenCode Stack

Self-hosted deployment of the OpenCode server (`opencode serve`) — the v2 API
plus bundled web UI for AI coding-agent sessions, running in Docker parallel
to the host's existing `opencode serve` systemd service (which is never
touched). Server state (SQLite, credentials, config) and project trees live
on named volumes.

## 🧩 Components

### 🖥️ [OpenCode Server](app/)

The single `opencode` service on the published upstream image
`ghcr.io/anomalyco/opencode:2.2.5` with a thin `dockerfile_inline` FROM-layer
(XDG roots, config dir, serve-flag entrypoint), with forwarding /
letsencrypt / step-ca environments behind the collection's nginx-proxy
stacks. Plugin support is a base feature: the committed
[`app/components/base/plugins/`](app/components/base/plugins/) scripts
(micode, dcp, rtk, headroom) are baked into the image, and a single
space-separated `PLUGINS` env list selects which of them the entrypoint
installs at container start (markers under `/data/plugins/.installed` are
injected into the config via `OPENCODE_CONFIG_CONTENT`).

### 🌐 [Let's Encrypt Manager](modules/ssl-automation/letsencrypt-manager/)

Automatic SSL certificate generation and renewal using Let's Encrypt for
production deployments with internet access.

### 🔒 [Step CA Manager](modules/ssl-automation/step-ca-manager/)

Self-signed trusted certificate authority for virtual Docker networks
without internet access. Automatically manages and distributes CA
certificates within isolated environments.

## 🚀 Quick Start

```bash
cd app
sb build
cd build/forwarding
cp .env.example .env  # set OPENCODE_SERVER_PASSWORD (+ provider key or auth.json seeding)
docker compose up -d
```

`sb build` produces one flat directory per environment — `build/forwarding/`,
`build/letsencrypt/`, and `build/step-ca/` (the entire-trust combo) — pick the
one matching your deployment.

See [`app/README.md`](app/README.md) for the full runbook.

## 📋 Requirements

- Docker & Docker Compose
- A server password (`OPENCODE_SERVER_PASSWORD`) for the web UI / API
- A provider model key for agent sessions (env var or `auth.json` seeded
  into the data volume — never committed to the repo)
- Domain name + email (for the Let's Encrypt environment)

## 📄 License

This project is dual-licensed under:

- [Apache License 2.0](LICENSE-APACHE)
- [MIT License](LICENSE-MIT)
