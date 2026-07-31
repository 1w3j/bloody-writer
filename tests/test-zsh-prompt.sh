#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p "$test_root/home/.oh-my-zsh"
: >"$test_root/home/.oh-my-zsh/oh-my-zsh.sh"

HOME="$test_root/home" USER="inherited-user-does-not-match" \
  BLOODY_WRITER_ZSHRC="$repo_root/dotfiles/zsh/.zshrc" \
  zsh -dfc '
    source "$BLOODY_WRITER_ZSHRC"
    [[ -n "$USERNAME" ]]
    [[ "$USER" != "$USERNAME" ]]
    [[ "$DEFAULT_USER" == "$USERNAME" ]]
  '

printf 'Agnoster local-user suppression test passed.\n'
