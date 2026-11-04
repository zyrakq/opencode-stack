# 🤖 OpenCode Server

A modular Docker Compose configuration system for self-hosting the OpenCode
server (`opencode serve`) — the v2 API plus bundled web UI for AI
coding-agent sessions, with server state (SQLite, credentials, config) and
project trees on named volumes. Runs parallel to the host's existing
`opencode serve` systemd service, which is never modified.

## 🚀 Quick Start

### 1. Build Configurations

```bash
sb build
```

This creates one flat build directory per environment under `build/` —
`build/forwarding/`, `build/letsencrypt/`, `build/step-ca/` — each containing
that environment's single combo (see [`stackbuilder.toml`](stackbuilder.toml)).

### 2. Choose Your Configuration

```bash
# For development with port forwarding
cd build/forwarding/

# For production with Let's Encrypt SSL
cd build/letsencrypt/

# For production with Step CA SSL (entire-trust combo)
cd build/step-ca/
```

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env: set OPENCODE_SERVER_PASSWORD (required).
# Provider keys: either set ANTHROPIC_API_KEY / OPENROUTER_API_KEY /
# OPENAI_API_KEY in .env, or seed auth.json into the data volume before the
# first start:
#   docker volume create opencode-stack-data
#   docker run --rm -v opencode-stack-data:/data -v "$HOME/.local/share/opencode/auth.json:/src/auth.json:ro" alpine \
#     cp /src/auth.json /data/opencode/auth.json
# (legacy credentials are imported into the server's SQLite on first boot)
```

### 4. Deploy

```bash
docker compose up -d
```

Access: `http://localhost:4096` (forwarding mode) or `https://<VIRTUAL_HOST>`
(proxy modes). Sign in with user `opencode` and `OPENCODE_SERVER_PASSWORD`.
Project trees live in the `opencode-stack-projects` volume (mounted at
`/projects` in the container); sessions resolve project directories from the
server filesystem — serve takes no project argument.

## 📁 Project Structure

- [`components/`](components/) — Source compose components
  - [`base/`](components/base/) — Base single-service configuration
    (incl. [`base/plugins/`](components/base/plugins/) install scripts)
  - [`environments/`](components/environments/) — Environment-specific configurations
  - [`extensions/`](components/extensions/) — Extension fragments
    (`repo-sync`, `repo-local`)
- [`build/`](build/) — Generated configurations (auto-generated, ready to deploy)
- [`stackbuilder.toml`](stackbuilder.toml) — Build configuration for stackbuilder

## 🔧 Available Configurations

### Environments

- **forwarding**: publishes port 4096 directly to the host
  (`OPENCODE_PUBLISH_PORT`, distinct from the host service's 8000)
- **letsencrypt**: joins `letsencrypt-network`; nginx-proxy terminates TLS
  and routes to `opencode:4096`; sets the public origin as the
  serve `--cors` value
- **step-ca**: joins `step-ca-network`; same wiring with the step-ca stack

### Plugins

Plugin support is a base feature, not an extension: the install scripts in
[`components/base/plugins/`](components/base/plugins/) (`micode`, `dcp`,
`rtk`, `headroom`) are baked into the image, and a single space-separated
`PLUGINS` env list selects which of them the entrypoint installs at
container start (stale `/data/plugins/.installed` markers are pruned, and
the surviving markers are injected into the config via
`OPENCODE_CONFIG_CONTENT` unless that variable is already set).

### Extensions

Each environment builds exactly one combo: **entire** (`forwarding`,
`letsencrypt`) or **entire-trust** (`step-ca`). The combo selects from the
extension menu in [`stackbuilder.toml`](stackbuilder.toml):

- **repo-sync**: sidecar (`alpine/git`) clones a git
  repo into the `opencode-stack-projects` volume and fast-forward-pulls it
  every `REPO_SYNC_INTERVAL` seconds. Configure via `REPO_SYNC_URL`
  (required), `REPO_SYNC_BRANCH`, `REPO_SYNC_DIR_NAME`, `REPO_SYNC_TOKEN`
  / `REPO_SYNC_USER` (https auth), `REPO_SYNC_SSH_KEY` (ssh URLs).
- **repo-local**: swap-in alternative to repo-sync (both own `/projects` —
  never both): bind-mounts a host path
  (`REPOS_PATH`, required) at `/projects` instead of the named volume —
  use existing working copies in place. To switch, replace `repo-sync`
  with `repo-local` in the combo in `stackbuilder.toml` and rebuild. This
  is a deliberate exception to the collection's no-bind-mount policy: the
  working copies live on the host and must be used in place (edits visible
  both ways).

- **step-ca-trust**: mandatory in every step-ca combo — mounts the step-ca
  root CA read-only, installs it into the container trust store and sets
  `NODE_EXTRA_CA_CERTS` so outbound HTTPS to step-ca-signed services works.

`sb build` generates one flat directory per environment under `build/`
(single combo per environment, no combo subdirectories).

## 🔐 Persistence

- `opencode-stack-data` → `/data` (XDG data/state/cache roots + config dir;
  SQLite DB, credentials, logs)
- `opencode-stack-projects` → `/projects` (project trees; provisioned by
  the `repo-sync` extension or replaced by the `repo-local` bind mount)
