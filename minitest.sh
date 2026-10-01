#!/usr/bin/env bash

set -eo pipefail

PLUGIN_NAME=${PLUGIN_NAME:-"kulala"}
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS=${PLUGINS:-"https://github.com/nvim-mini/mini.test.git;mini.test file://$CURRENT_DIR;$PLUGIN_NAME"}

CURRENT_DATESTR=$(date +"%Y-%m-%d-%H-%M-%S")
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/tmp.nvim-test-isolation-${CURRENT_DATESTR}.XXXXXX")

function cleanup {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

{
  echo "#!/usr/bin/env bash"
  echo
  echo "set -eo pipefail"
  echo
  echo export KULALA_CORE_LICENSE_TOKEN="$KULALA_CORE_LICENSE_TOKEN"
  echo "nvim --headless -i NONE --noplugin -u \"$TMP_DIR/minitest.lua\""
} > "$TMP_DIR/minitest.sh"

chmod +x "$TMP_DIR/minitest.sh"
{
  echo "local vim = vim or {}"
  echo "vim.env = vim.env or {}"
  echo "vim.env.XDG_DATA_HOME = '$TMP_DIR/data'"
  echo "vim.env.XDG_STATE_HOME = '$TMP_DIR/state'"
  echo "vim.env.XDG_CACHE_HOME = '$TMP_DIR/cache'"
  echo "vim.env.XDG_CONFIG_HOME = '$TMP_DIR/config'"
  echo "vim.env.NVIM_REPRO_TMP_DIR = '$TMP_DIR'"
  echo "vim.env.PLUGINS = '$PLUGINS'"
  echo
} > "$TMP_DIR/minitest.lua"
cat minitest.lua >> "$TMP_DIR/minitest.lua"
echo "Running tests in isolation..."
echo "Temporary directory: $TMP_DIR"

"$TMP_DIR/minitest.sh"

rm -rf "$TMP_DIR"
