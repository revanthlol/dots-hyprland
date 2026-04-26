# This script is meant to be sourced.
# shellcheck shell=bash

DOTS="$REPO_ROOT/dots/.config"

symlink_config() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak"
    printf "${STY_YELLOW}Backed up existing $dst to $dst.bak${STY_RST}\n"
  fi
  ln -sfn "$src" "$dst"
  printf "${STY_GREEN}Linked: $dst -> $src${STY_RST}\n"
  realpath -se "$dst" >> "${INSTALLED_LISTFILE}"
}

# MISC configs (kitty, rofi, matugen, etc — everything except qs/fish/hypr)
for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 \
  ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' \
  -exec basename {} \;); do
  symlink_config "$REPO_ROOT/dots/.config/$i" "$XDG_CONFIG_HOME/$i"
done

# Quickshell
symlink_config "$REPO_ROOT/dots/.config/quickshell" "$XDG_CONFIG_HOME/quickshell"

# Fish
symlink_config "$REPO_ROOT/dots/.config/fish" "$XDG_CONFIG_HOME/fish"

# Hyprland
symlink_config "$REPO_ROOT/dots/.config/hypr/hyprland" "$XDG_CONFIG_HOME/hypr/hyprland"
symlink_config "$REPO_ROOT/dots/.config/hypr/hyprland.conf" "$XDG_CONFIG_HOME/hypr/hyprland.conf"
symlink_config "$REPO_ROOT/dots/.config/hypr/hyprlock.conf" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
symlink_config "$REPO_ROOT/dots/.config/hypr/hypridle.conf" "$XDG_CONFIG_HOME/hypr/hypridle.conf"
symlink_config "$REPO_ROOT/dots/.config/hypr/monitors.conf" "$XDG_CONFIG_HOME/hypr/monitors.conf"
symlink_config "$REPO_ROOT/dots/.config/hypr/workspaces.conf" "$XDG_CONFIG_HOME/hypr/workspaces.conf"

# Custom hypr (don't overwrite if exists — user edits live here)
if [ ! -e "$XDG_CONFIG_HOME/hypr/custom" ]; then
  symlink_config "$REPO_ROOT/dots/.config/hypr/custom" "$XDG_CONFIG_HOME/hypr/custom"
fi
