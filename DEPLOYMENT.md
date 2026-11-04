# DEPLOYMENT.md — opencode-stack

Deployment model of the upstream product, per stack-conventions §20.
Produced by the `stack-analysis` skill (workflow session 2026-11-04).
Upstream: https://github.com/anomalyco/opencode, pinned tag `v2.2.5`.
Goal: run the OpenCode server in Docker, parallel to the user's existing
host `opencode serve` systemd service — the host setup is read-only and
never modified.

## Product parts

Inventory from the upstream clone at tag `v2.2.5`:

| Part | Upstream evidence | Image source |
|------|------------------|--------------|
| `opencode-server` — v2 API + web UI + agent sessions (`opencode serve`) | `packages/cli/src/commands/handlers/serve.ts`, `packages/server/`, web UI `packages/app` is bundled and served by the server ("Start the v2 API and web server") | published: `ghcr.io/anomalyco/opencode:2.2.5` (alpine + prebuilt bun binary, multi-arch, `packages/cli/Dockerfile`, `.github/release/publish-docker.sh`) |

Not separate parts (bundled or alternatives, no compose service):

- **TUI** (`packages/tui`) — interactive runs on a desktop/PTY; the server
  part is its own deployment. No service.
- **Desktop** (`packages/desktop`) — Electron app; client-side, no service.
- **CLI as SDK** — the binaries are no-op clients inside a server container.
- Separate **frontend** deploy — none: `opencode serve` serves the web UI
  itself (confirmed: no standalone web dist image in release artifacts).
- **Storage** — embedded SQLite via `packages/effect-drizzle-sqlite`
  (server-managed, no external DB part).

Upstream serve flags at `v2.2.5`: `--hostname`, `--port`, `--cors`
(repeatable), `--service`, `--stdio`. No project-directory CLI arg: the
server resolves session/project directories against its own filesystem
(`packages/server/src/routes.ts` config `directory`,
`packages/cli/src/session-target.ts` `location.directory`), so project
dirs must exist under container paths (provisioned volume). Credentials:
`OPENCODE_PASSWORD` / `OPENCODE_SERVER_PASSWORD` (redacted env,
`packages/cli/src/env.ts`); config dir env: `OPENCODE_CONFIG_DIR`
(`packages/cli/src/server-process.ts`).

## Interaction map

- **user/browser → opencode-server**: HTTPS (via the SSL stack proxy) —
  web UI, REST API, auth via `OPENCODE_SERVER_PASSWORD`. `--cors` sets an
  additional allowed origin.
- **opencode-server → LLM provider APIs** (outbound): model calls using
  provider keys from config env. Breaks the product's core value if
  absent — model provider keys are a gate prerequisite, not an optional
  feature.
- **opencode-server → project directories (local FS paths in-container)**:
  sessions read/write the project tree. No external part; provisioning of
  real repos becomes the `repo-sync`/`repo-local` extensions.
- Grouping: single part → single group `app-core`. No inter-group links;
  the outbound LLM-API call goes to a third-party service, not another
  collection group — when it runs against internal endpoints over custom
  CA (e.g. a local provider), `step-ca-trust` applies.

## Functional base

| Item | Tier | Justification |
|------|------|---------------|
| `opencode-stack-app` (`opencode serve` + bundled web UI) | core | the product; one part, exercised end-to-end by the gate |
| `opencode-stack-data` volume (server state: SQLite, auth) | core | server-managed persistent state, without it every restart loses projects/sessions/config |
| `opencode-stack-projects` volume (project trees under a fixed container path) | core | sessions resolve project directories from the server filesystem (serve has no project arg) — the base ships the volume the gate provisions a throwaway project into |
| Provider model keys (env fragment into the app) | core (gate-enabling) | a session needs a working model; credentials are a gate prerequisite per stack-analysis rule 9 — no menu confirmation |
| Version/config layer via `dockerfile_inline` over `${IMAGE:-ghcr.io/anomalyco/opencode:2.2.5}` | core | published upstream image is the base; a thin FROM-layer carries config/defaults without a source build |

Mandatory infra attempts (stack-analysis rule 4) — all REFUSED with
reasons, recorded here as required, never silently dropped:

- **PostgreSQL (postgresql+pgrust)** — REFUSED: the product persists via
  embedded SQLite (`packages/effect-drizzle-sqlite` in the server); no
  upstream config surface for an external database exists. Nothing to
  wire; a DB container would be dead weight outside the gate scenario
  (overreach guard).
- **OIDC (kanidm)** — REFUSED: `v2.2.5` auth is the redacted server
  password (`OPENCODE_PASSWORD` / `OPENCODE_SERVER_PASSWORD`); the OSM
  server exposes no OIDC/OAuth SSO configuration on the serve surface. If
  a later upstream version adds SSO, re-run gap analysis.
- **S3 (s3-storage)** — REFUSED: no S3/storage-object configuration in the
  upstream deployment surface; state is the SQLite file + project trees on
  the named volumes.

## Base stage plan

Single group → single stage.

- **Stage A (core, `app-core`)**: `opencode-stack-app` + `opencode-stack-data`
  + `opencode-stack-projects` + provider key env. Gate scenario (real run
  of the product's main work):
  1. `opencode serve --hostname 0.0.0.0 --port <port>` comes up healthy;
  2. browser opens the environment origin (forwarding: local port; TLS
     overlays: `https://<vhost>`) — web UI loads, password auth accepts
     `OPENCODE_SERVER_PASSWORD`;
  3. open the gate-throwaway project (a small git repo provisioned inside
     the `opencode-stack-projects` mount during the test); a session opens
     over that directory;
  4. send one prompt; the wire turns a provider key into a model response
     streamed into the UI;
  5. restart the stack: the project/session survives
     (`opencode-stack-data`/`-projects` persistence).
- Outer groups: none exist, so no cross-group links and no other gates.
  `step-ca-trust` is deferred to the environments/extensions below.

Env-var note: the host setup uses a DJB-style redacted password var; this
stack treats the credential as a required var (`OPENCODE_SERVER_PASSWORD:?`)
declared in the owning fragment, with the container's own hostname/port
and CORS origin (`--cors` flag value) separate from the host service.

## Extension catalog

Extensions are implemented one at a time after the extension-menu
checkpoint, each gated by its own stack-test stage. `repo-sync` and
`repo-local` are implemented (gated on the step-ca env with repo-sync:
clone into `opencode-stack-projects` verified, ff-pull loop verified, app
healthy); the rest remain `available`.

| Extension | Type | Status | Dependencies / notes |
|-----------|------|--------|----------------------|
| `model-keys` (provider model/provider API keys env) | infra | required-for-gate | one provider key is needed by the Stage A gate; implemented with the core, no menu confirmation; additional providers stay in this fragment |
| `repo-sync` | product | implemented | sidecar clones upstream repos into `opencode-stack-projects` at the fixed container path (pattern precedented in the collection for project provisioning); turns the throwaway gate project into real trees |
| `repo-local` | product | implemented | policy-exception bind variant of repo-sync (`${REPOS_PATH:?}`); mutually exclusive with `repo-sync` |
| `plugins` | product | implemented | ONE extension, per-plugin env toggles baked via the `dockerfile_inline` FROM-layer over `${IMAGE}`: `PLUGINS_MICODE` (git tarball `https://codeload.github.com/pjotrvv/micode/tar.gz/<sha>` @ `2469fea` → `/opt/plugins/micode-v2`, prebuilt v2-adapter `lib/` + `npm install --omit=dev`), `PLUGINS_DCP` (npm `@tarquinen/opencode-dcp@3.2.0` — pin validated at build, installed at runtime by opencode's in-process npm into `/data/cache/opencode/npm/`), `PLUGINS_RTK` (GitHub release binary `rtk-ai/rtk` v1.1.0 musl, sha256-pinned → `/usr/local/bin/rtk`; shim generated by `rtk init -g --opencode` → `/opt/plugins/rtk/index.ts`), `PLUGINS_HEADROOM` (pip `headroom-ai==0.20.15` CLI, staged deps, no plugin entry — used via `docker exec`); all fetched from their own upstream sources, never copied from the host. Wiring: install scripts drop marker files in `/opt/plugins/.installed/` (content = literal config entry); the flat `entrypoint.sh` (overrides base) reads markers and exports `OPENCODE_CONFIG_CONTENT={"plugins":[...]}` — no runtime writes to persistent `/data/config`. Gated on the step-ca env with all 4 toggles on: markers ✓, `OPENCODE_CONFIG_CONTENT` in PID1 env ✓, dcp runtime-installed + cached across restart ✓, micode bridged 6 hooks / 26 agents / 4 commands ✓, rtk binary + shim in place (silent transport shim — rewrites on tool-execution hooks) ✓, headroom CLI 0.20.15 ✓, Basic auth + config doc `plugins` list ✓ |
| `step-ca-trust` | infra | available | needed only if the app calls another collection group by public HTTPS domain; the outbound LLM-API default call goes to third-party providers, so not mandatory in the default comb |
| TLS environments (`forwarding` / `letsencrypt` / `step-ca`) | environment overlays | planned with the core scaffold | CORS origin (public `https://...` used with `--cors`) and public URL defaults are environment-dependent → declared ONLY in overlays, never in base |

Sources verified as installable from upstream (no host material needed):
micode = git repo (clonable), dcp = npm package, headroom = PyPI package,
rtk = GitHub release binary.

## Open hypotheses

| # | Hypothesis | Confidence | What the functional gate observes to settle it |
|---|-----------|------------|-----------------------------------------------|
| 1 | The published image is usable as-is as the base (`FROM` layer instead of a source build): plugins/config can be baked from a thin `dockerfile_inline` layer because upstream's image is alpine with a shell and the plugin surface resolves from the config dir (`OPENCODE_CONFIG_DIR`) | settled | Stage A ran on the layered image; the `plugins` extension stage settled the wiring: plugin entries inject via the `OPENCODE_CONFIG_CONTENT` virtual config doc (marker-driven `entrypoint.sh`), not the config dir — dcp installs at runtime into `/data/cache/opencode/npm/`, micode/rtk load from image-bake paths |
| 2 | Sessions discover projects purely from container filesystem paths given to the API (no server restart/registration needed for a newly mounted project dir) | medium | gate: open a session against the throwaway project created after serve started |
| 3 | Auth = HTTP basic/ bearer challenge against `OPENCODE_SERVER_PASSWORD` before the web UI is reachable | medium-high | gate: unauthenticated browser request to the UI origin → challenge; with the env → UI loads |
| 4 | The web UI served by `opencode serve` talks to the same origin (no separate frontend part) — `--cors` is only an extra origin allowance | high | gate: one origin serves UI+API with no cross-origin console errors |
