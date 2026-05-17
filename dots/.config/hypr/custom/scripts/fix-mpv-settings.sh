#!/bin/bash
set -euo pipefail

MPV_CONF="$HOME/.config/mpv/mpv.conf"

mkdir -p "$(dirname "$MPV_CONF")"
touch "$MPV_CONF"

SETTINGS=(
  "keep-open=yes"
  "target-colorspace-hint=no"
  "save-position-on-quit=yes"
  "cursor-autohide=1000"
  "geometry=50%:50%"
  "autofit-larger=100%x100%"
  "ao=pulse"
)

for setting in "${SETTINGS[@]}"; do
  if ! grep -qxF "$setting" "$MPV_CONF"; then
    printf '%s\n' "$setting" >> "$MPV_CONF"
  fi
done
