# components/base/plugins — OpenCode plugin install scripts

Runtime plugin support for the base image. The scripts in this folder are
committed here and copied by the base `dockerfile_inline` build
(`COPY plugins /opt/plugins`) into `/opt/plugins` inside the image — no
manual copying into build dirs, no image rebuild to change the selection.

## Enabling plugins

Add plugin name tokens to the space-separated `PLUGINS` env in the build
dir's `.env` (see `.env.example`):

    PLUGINS=micode rtk

At container start the base entrypoint runs `/opt/plugins/install-<token>.sh`
for each token (unknown tokens are logged and skipped), so plugins install
into the persistent `/data` volume — no rebuild needed. Changing `PLUGINS`
and restarting the container installs newly added plugins; markers for
removed tokens are pruned from `/data/plugins/.installed/`.

After installing, each script records a marker file under
`/data/plugins/.installed/<token>` containing the plugin entry string. The
entrypoint collects the surviving markers and injects them into the config
via `OPENCODE_CONFIG_CONTENT` — only if that variable is not already set
(set it yourself to take full control of the config).

## Bundled plugins

`micode`, `dcp`, `rtk`, `headroom` (see the `install-*.sh` scripts and
`common.sh` for the shared marker helper).

## Custom plugins

Add your own `install-<token>.sh` script to this folder (same convention,
use `common.sh` for the marker mechanism) and enable it with its token in
`PLUGINS`. `sb build` copies the whole folder into every build dir's
`plugins/` (git-ignored there) automatically.
