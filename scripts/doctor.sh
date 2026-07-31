#!/usr/bin/env bash
set -Eeuo pipefail

BW_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
export BW_REPO_ROOT
# shellcheck disable=SC1091
source "$BW_REPO_ROOT/scripts/lib/common.sh"

failures=0
warnings=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  [OK]   %s\n' "$label"
  else
    printf '  [FAIL] %s\n' "$label"
    failures=$((failures + 1))
  fi
}

warn_check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  [OK]   %s\n' "$label"
  else
    printf '  [WARN] %s\n' "$label"
    warnings=$((warnings + 1))
  fi
}

is_systemd() {
  [[ $(ps -p 1 -o comm= | tr -d '[:space:]') == systemd ]]
}

is_linked_to() {
  [[ -L $2 ]] && [[ $(readlink -f -- "$2") == "$(readlink -f -- "$1")" ]]
}

has_commands() {
  local name
  for name in "$@"; do
    command -v "$name" >/dev/null 2>&1 || return 1
  done
}

codex_logged_in() {
  [[ -x $HOME/.local/bin/codex ]] &&
    env CODEX_HOME="$HOME/.codex" "$HOME/.local/bin/codex" login status
}

github_logged_in() {
  gh auth status
}

github_key_exists() {
  find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_ed25519_github_*' -print -quit 2>/dev/null |
    grep -q .
}

printf 'Bloody Writer doctor — %s\n\n' "$BLOODY_WRITER_VERSION"
check "Arch Linux" bw_is_arch
check "WSL" bw_is_wsl
check "systemd is PID 1" is_systemd
check "core commands" has_commands zsh nvim tmux git gh rg fd fzf jq node npm pnpm python
check "Zsh configuration link" is_linked_to "$BW_REPO_ROOT/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
check "tmux configuration link" is_linked_to "$BW_REPO_ROOT/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
check "Neovim configuration link" is_linked_to "$BW_REPO_ROOT/dotfiles/nvim/.config/nvim" "$HOME/.config/nvim"
check "tmux picker link" is_linked_to "$BW_REPO_ROOT/dotfiles/local-bin/.local/bin/tma" "$HOME/.local/bin/tma"
check "Bloody Writer command link" is_linked_to "$BW_REPO_ROOT/bin/bloody-writer" "$HOME/.local/bin/bloody-writer"
warn_check "Codex authenticated" codex_logged_in
warn_check "GitHub CLI authenticated" github_logged_in
warn_check "GitHub SSH key configured" github_key_exists
warn_check "English spell file" test -s "$HOME/.local/share/nvim/site/spell/en.utf-8.spl"
warn_check "Spanish spell file" test -s "$HOME/.local/share/nvim/site/spell/es.utf-8.spl"

printf '\nResult: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
((failures == 0))
