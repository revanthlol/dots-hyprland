#!/bin/bash
set -euo pipefail

CUSTOM_CONF="$HOME/.config/hypr/custom/kitty.conf"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
LOGFILE="$HOME/.local/share/fix-kitty.log"

mkdir -p "$(dirname "$LOGFILE")"
mkdir -p "$(dirname "$CUSTOM_CONF")"
mkdir -p "$(dirname "$KITTY_CONF")"
touch "$CUSTOM_CONF"
touch "$KITTY_CONF"

timestamp() { date +"[%Y-%m-%d %H:%M:%S]"; }

NORMAL_CUSTOM_CONF="$(realpath "$CUSTOM_CONF")"
INCLUDE_LINE="include $NORMAL_CUSTOM_CONF"

if ! grep -Eq "include[[:space:]]+${NORMAL_CUSTOM_CONF//\//\\/}" "$KITTY_CONF"; then
  echo "$INCLUDE_LINE" >> "$KITTY_CONF"
  echo "$(timestamp) Added include line to kitty.conf" >> "$LOGFILE"
else
  echo "$(timestamp) Include already present, skipping" >> "$LOGFILE"
fi

if pgrep -x kitty >/dev/null; then
  kitty @ set-background-opacity 0.3 2>/dev/null || true
  echo "$(timestamp) Reloaded kitty opacity" >> "$LOGFILE"
fi
