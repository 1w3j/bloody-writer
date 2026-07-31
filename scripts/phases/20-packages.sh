#!/usr/bin/env bash

phase_20_packages() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  case "$BW_PLATFORM" in
  wsl) phase_20_arch_packages ;;
  termux) phase_20_termux_packages ;;
  *) bw_die "Package phase does not support: $BW_PLATFORM" ;;
  esac
}

phase_20_arch_packages() {
  local packages=()
  mapfile -t packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$BW_REPO_ROOT/manifests/arch-packages.txt")
  ((${#packages[@]})) || bw_die "The Arch package manifest is empty."

  bw_log "Updating Arch and installing the tracked workstation packages."
  bw_confirm "Allow pacman to perform a full Arch upgrade and install ${#packages[@]} packages?" || return 1
  bw_run sudo pacman -Syu --needed "${packages[@]}"

  local npm_packages=()
  mapfile -t npm_packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$BW_REPO_ROOT/manifests/npm-globals.txt")
  ((${#npm_packages[@]})) || bw_die "The npm package manifest is empty."
  bw_log "Installing the tracked Node-based language tools."
  bw_run sudo npm install --global "${npm_packages[@]}"
}

phase_20_termux_packages() {
  local packages=()
  mapfile -t packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$BW_REPO_ROOT/manifests/termux-packages.txt")
  ((${#packages[@]})) || bw_die "The Termux package manifest is empty."

  bw_log "Updating Termux on Android and installing the tracked mobile-workstation packages."
  bw_confirm "Allow pkg to upgrade Termux and install ${#packages[@]} packages?" || return 1
  bw_run pkg update -y
  bw_run pkg upgrade -y
  bw_run pkg install -y "${packages[@]}"

  local npm_packages=()
  mapfile -t npm_packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$BW_REPO_ROOT/manifests/npm-globals.txt")
  ((${#npm_packages[@]})) || bw_die "The npm package manifest is empty."
  bw_log "Installing the tracked Node-based language tools in Termux."
  bw_run npm install --global "${npm_packages[@]}"

  if ! bw_have black; then
    bw_log "Installing the Black Python formatter for the Android user."
    bw_run python -m pip install black
  fi
}
