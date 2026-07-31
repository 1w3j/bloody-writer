#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

export HOME="$test_root/home"
export XDG_STATE_HOME="$test_root/state"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$test_root/cache"
export BW_STATE_DIR="$XDG_STATE_HOME/bloody-writer"
export BW_CONFIG_DIR="$XDG_CONFIG_HOME/bloody-writer"
export BW_CACHE_DIR="$XDG_CACHE_HOME/bloody-writer"
export BW_TEST_MODE=1
export BW_PLATFORM=wsl

mkdir -p "$HOME"
"$repo_root/bin/bloody-writer" install --yes --skip-github --skip-codex-login

for phase in \
  00-preflight 10-system 20-packages 25-host-theme 30-shell 40-dotfiles \
  50-neovim 60-codex 90-verify; do
  [[ -f $BW_STATE_DIR/completed/$phase ]]
done
[[ ! -e $BW_STATE_DIR/completed/70-github ]]

status_output="$("$repo_root/bin/bloody-writer" status)"
grep -q '90-verify.*complete' <<<"$status_output"
status_output="$("$HOME/.local/bin/bloody-writer" status)"
grep -q '40-dotfiles.*complete' <<<"$status_output"
[[ -x $HOME/.local/bin/bw-clipboard-copy ]]
"$repo_root/bin/bloody-writer" reset-phase 50-neovim
[[ ! -e $BW_STATE_DIR/completed/50-neovim ]]
"$repo_root/bin/bloody-writer" install --yes --only 50-neovim
[[ -f $BW_STATE_DIR/completed/50-neovim ]]
"$repo_root/bin/bloody-writer" install --yes --only 70-github
[[ -f $BW_STATE_DIR/completed/70-github ]]

printf 'Resume-state test passed.\n'
