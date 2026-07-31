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
printf 'Platform: %s\n\n' "$(bw_platform_label)"
case "$BW_PLATFORM" in
wsl)
  check "Arch Linux" bw_is_arch
  check "Windows WSL 2" bw_is_wsl
  check "systemd is PID 1" is_systemd
  check "WSL core commands" has_commands zsh nvim tmux git gh rg fd fzf jq node npm pnpm python powershell.exe clip.exe
  ;;
termux)
  check "Termux on Android" bw_is_termux
  check "Termux core commands" has_commands zsh nvim tmux git gh rg fd fzf jq node npm python pkg
  check "Android clipboard bridge" has_commands termux-clipboard-get termux-clipboard-set
  warn_check "Android shared storage" test -d "$HOME/storage/shared"
  warn_check "Termux Nerd Font" test -s "$HOME/.termux/font.ttf"
  ;;
*)
  printf '  [FAIL] Unsupported environment; use Arch Linux on Windows WSL or Termux on Android.\n'
  failures=$((failures + 1))
  ;;
esac
check "Zsh configuration link" is_linked_to "$BW_REPO_ROOT/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
check "tmux configuration link" is_linked_to "$BW_REPO_ROOT/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
check "Neovim configuration link" is_linked_to "$BW_REPO_ROOT/dotfiles/nvim/.config/nvim" "$HOME/.config/nvim"
check "tmux picker link" is_linked_to "$BW_REPO_ROOT/dotfiles/local-bin/.local/bin/tma" "$HOME/.local/bin/tma"
check "clipboard helper link" is_linked_to "$BW_REPO_ROOT/dotfiles/local-bin/.local/bin/bw-clipboard-copy" "$HOME/.local/bin/bw-clipboard-copy"
check "Bloody Writer command link" is_linked_to "$BW_REPO_ROOT/bin/bloody-writer" "$HOME/.local/bin/bloody-writer"
case "$BW_PLATFORM" in
wsl)
  warn_check "Codex authenticated in WSL" codex_logged_in
  ;;
termux)
  warn_check "Remote WSL host configured" test -n "${BLOODY_WRITER_WSL_HOST:-}"
  ;;
esac
warn_check "GitHub CLI authenticated" github_logged_in
warn_check "GitHub SSH key configured" github_key_exists
warn_check "English spell file" test -s "$HOME/.local/share/nvim/site/spell/en.utf-8.spl"
warn_check "Spanish spell file" test -s "$HOME/.local/share/nvim/site/spell/es.utf-8.spl"

printf '\nResult: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
((failures == 0))
