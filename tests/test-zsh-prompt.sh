#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p "$test_root/home/.oh-my-zsh"
: >"$test_root/home/.oh-my-zsh/oh-my-zsh.sh"
mkdir -p "$test_root/home/.local/bin"
ln -s "$repo_root/bin/bloody-writer" "$test_root/home/.local/bin/bloody-writer"

HOME="$test_root/home" USER="inherited-user-does-not-match" \
  BLOODY_WRITER_ZSHRC="$repo_root/dotfiles/zsh/.zshrc" \
  zsh -dfc '
    source "$BLOODY_WRITER_ZSHRC"
    [[ $path[1] == "$HOME/.local/bin" ]]
    [[ ${path[(I)$HOME/.local/bin]} -eq 1 ]]
    [[ $(command -v bloody-writer) == "$HOME/.local/bin/bloody-writer" ]]
    [[ -n "$USERNAME" ]]
    [[ "$USER" != "$USERNAME" ]]
    [[ "$DEFAULT_USER" == "$USERNAME" ]]
  '

printf 'Zsh command path and Agnoster local-user suppression tests passed.\n'
