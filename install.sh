#!/bin/bash

# Install BOSS Notification Manager in place of Omarchy's built-in
# notifications plugin. Works the way `omarchy plugin clone` does: the plugin
# is copied into ~/.config/omarchy/plugins and enabled, and its manifest's
# omarchy.clonedFrom makes the shell route the built-in's calls to it.
#
# Usage: ./install.sh [--force]
#   --force  install even on an Omarchy version this was not tested on

set -euo pipefail

readonly ID=boss.notifications
# Omarchy versions whose notifications plugin this one was built from.
readonly TESTED_VERSIONS=("4.0.6-1")

PLUGINS_DIR="$HOME/.config/omarchy/plugins"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

fail() {
  echo "install.sh: $*" >&2
  exit 1
}

force=0
case ${1:-} in
"") ;;
--force) force=1 ;;
-h | --help)
  sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
  ;;
*) fail "unknown option: $1" ;;
esac

command -v omarchy-shell >/dev/null || fail "this needs Omarchy (omarchy-shell was not found)"

version=$(omarchy version 2>/dev/null || true)
if [[ ! " ${TESTED_VERSIONS[*]} " == *" $version "* ]] && ((!force)); then
  echo "install.sh: tested on Omarchy ${TESTED_VERSIONS[*]}, this is ${version:-unknown}." >&2
  echo "The built-in notifications plugin may have changed since. Run with --force to install anyway." >&2
  exit 1
fi

target="$PLUGINS_DIR/$ID"
if [[ -e $target || -L $target ]]; then
  existing=$(jq -r '.id // empty' "$target/manifest.json" 2>/dev/null || true)
  [[ $existing == "$ID" ]] || fail "$target exists and is not BOSS Notification Manager; leaving it alone"
fi

# Stage next to the target (a dot name the plugin scan skips), then swap it in
# with renames, so the shell never sees a half-copied plugin.
mkdir -p "$PLUGINS_DIR"
stage=$(mktemp -d "$PLUGINS_DIR/.boss-install.XXXXXX")
old=""
cleanup() {
  [[ -n $stage && -d $stage ]] && rm -rf "$stage"
  [[ -n $old && -d $old ]] && rm -rf "$old"
  return 0
}
trap cleanup EXIT

cp -a "$here/plugin/." "$stage/"
if [[ -e $target ]]; then
  old="$PLUGINS_DIR/.boss-old.$$"
  mv "$target" "$old"
fi
mv "$stage" "$target"
stage=""

omarchy-shell shell rescanPlugins >/dev/null

discovered=0
for ((attempt = 0; attempt < 40; attempt++)); do
  if omarchy-plugin-list --json | jq -e --arg id "$ID" 'any(.[]; .id == $id)' >/dev/null; then
    discovered=1
    break
  fi
  sleep 0.05
done
((discovered)) || fail "the shell did not pick up $ID; run: omarchy-shell shell rescanPlugins"

omarchy-plugin-enable "$ID" >/dev/null

# Notification services are keepLoaded: a plugin reload leaves the running
# one in place, so only a shell restart hands the notification server over.
# Toasts on screen survive it (they are restored from their files).
omarchy-restart-shell >/dev/null
echo "Installed $ID in $target and restarted the shell to switch notifications over to it."
