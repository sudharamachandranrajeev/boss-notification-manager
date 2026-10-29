#!/bin/bash

# Remove BOSS Notification Manager and go back to Omarchy's built-in
# notifications plugin. Notification history and do-not-disturb live in
# ~/.local/state/omarchy and are shared with the built-in, so they stay.

set -euo pipefail

readonly ID=boss.notifications

if [[ ! -e $HOME/.config/omarchy/plugins/$ID ]]; then
  echo "BOSS Notification Manager is not installed."
  exit 0
fi

omarchy-plugin-remove "$ID" --yes
# omarchy-plugin-remove keeps a backup of the folder. It is only the
# installed copy of this repo's plugin/, so drop it.
rm -rf "$HOME/.config/omarchy/plugins/.$ID.bak."*
# The service is keepLoaded, so it runs until the shell restarts.
omarchy-restart-shell >/dev/null
echo "Removed $ID and restarted the shell; Omarchy's built-in notifications are back."
