#!/usr/bin/env bash

phase_20_packages() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

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
