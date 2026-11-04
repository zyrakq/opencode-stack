# app/plugins — ready-made OpenCode plugin install scripts

Ready-made install scripts for the `plugins` extension. They are NOT used
from this folder directly: copy them into the build dir's `plugins/` folder
(git-ignored, absent by default) next to `docker-compose.yml`:

    mkdir -p app/build/<env>/<combo>/plugins
    cp app/plugins/*.sh app/build/<env>/<combo>/plugins/

Then set the per-plugin toggles in `.env` (see the plugins extension
`.env.example`): `PLUGINS_MICODE` / `PLUGINS_DCP` / `PLUGINS_RTK` /
`PLUGINS_HEADROOM`, and `docker compose build`.

`docker compose build` runs every `install-*.sh` found in the folder at
image build time; the base entrypoint injects the resulting plugin entries
via `OPENCODE_CONFIG_CONTENT`. Add your own `install-*.sh` scripts
alongside — same convention, same marker mechanism (see `common.sh`).

⚠️ `sb build` regenerates the build dirs and wipes `plugins/` folders —
re-copy after every rebuild.
