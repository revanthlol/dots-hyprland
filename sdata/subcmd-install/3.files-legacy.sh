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
for i in $(find "${DOTS}/" -mindepth 1 -maxdepth 1 \
  ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' \
  -exec basename {} \;); do
  symlink_config "$DOTS/$i" "$XDG_CONFIG_HOME/$i"
done

# Quickshell
symlink_config "$DOTS/quickshell" "$XDG_CONFIG_HOME/quickshell"

# Fish
symlink_config "$DOTS/fish" "$XDG_CONFIG_HOME/fish"

# Hyprland
symlink_config "$DOTS/hypr" "$XDG_CONFIG_HOME/hypr"
