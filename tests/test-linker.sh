#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

export HOME="$test_root/home"
export XDG_STATE_HOME="$test_root/state"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$test_root/cache"
export BW_REPO_ROOT="$repo_root"
export BW_STATE_DIR="$XDG_STATE_HOME/bloody-writer"
export BW_CONFIG_DIR="$XDG_CONFIG_HOME/bloody-writer"
export BW_CACHE_DIR="$XDG_CACHE_HOME/bloody-writer"
export BW_TEST_MODE=1

mkdir -p "$HOME"
printf 'original zsh config\n' >"$HOME/.zshrc"

# shellcheck disable=SC1091
source "$repo_root/scripts/lib/common.sh"
bw_ensure_dirs
bw_link_managed "$repo_root/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
bw_link_managed "$repo_root/dotfiles/local-bin/.local/bin/tma" "$HOME/.local/bin/tma"

[[ -L $HOME/.zshrc ]]
[[ $(readlink -f "$HOME/.zshrc") == "$(readlink -f "$repo_root/dotfiles/zsh/.zshrc")" ]]
[[ -L $HOME/.local/bin/tma ]]
grep -Rqx 'original zsh config' "$BW_STATE_DIR/backups"
grep -q $'\t__MISSING__$' "$BW_BACKUP_DIR/manifest.tsv"

# A second pass must preserve the existing correct link and create no second backup.
backup_count="$(find "$BW_STATE_DIR/backups" -mindepth 1 -maxdepth 1 -type d | wc -l)"
bw_link_managed "$repo_root/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
[[ $(find "$BW_STATE_DIR/backups" -mindepth 1 -maxdepth 1 -type d | wc -l) == "$backup_count" ]]

BW_ASSUME_YES=1 "$repo_root/bin/bloody-writer" restore "$BW_BACKUP_DIR"
[[ ! -L $HOME/.zshrc ]]
grep -qx 'original zsh config' "$HOME/.zshrc"
[[ ! -e $HOME/.local/bin/tma && ! -L $HOME/.local/bin/tma ]]
if BW_ASSUME_YES=1 "$repo_root/bin/bloody-writer" restore "$BW_BACKUP_DIR" 2>/dev/null; then
  printf 'A consumed backup was incorrectly restored twice.\n' >&2
  exit 1
fi
grep -qx 'original zsh config' "$HOME/.zshrc"

printf 'Linker, backup, and restore test passed.\n'
