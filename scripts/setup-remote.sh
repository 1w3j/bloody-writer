#!/usr/bin/env bash
set -Eeuo pipefail

BW_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
export BW_REPO_ROOT
# shellcheck disable=SC1091
source "$BW_REPO_ROOT/scripts/lib/common.sh"

setup_wsl_remote_host() {
  bw_is_arch || bw_die "The WSL remote host must use Arch Linux."
  [[ $(ps -p 1 -o comm= | tr -d '[:space:]') == systemd ]] ||
    bw_die "systemd must be active. Finish the normal installer and restart WSL first."

  bw_warn "Remote access requires the Windows PC to remain powered on, awake, and running WSL."
  bw_confirm "Install Tailscale and enable private Tailscale SSH access on WSL?" || return 0

  sudo pacman -S --needed tailscale
  sudo systemctl enable --now tailscaled
  sudo tailscale up --ssh

  local tailscale_name tailscale_ip login
  tailscale_name="$(tailscale status --self --json 2>/dev/null | jq -r '.Self.DNSName // empty' | sed 's/\.$//')"
  tailscale_ip="$(tailscale ip -4 2>/dev/null | head -n 1)"
  login="${USER:-$(id -un)}"

  printf '\nWSL remote access is ready.\n\n'
  printf '1. Install the Tailscale Android app and sign in to the same tailnet.\n'
  printf '2. Open Termux on Android and run: bloody-writer remote\n'
  if [[ -n $tailscale_name ]]; then
    printf '3. Use this WSL host when prompted: %s\n' "$tailscale_name"
  else
    printf '3. Use this WSL host when prompted: %s\n' "$tailscale_ip"
  fi
  printf '4. Use this WSL user when prompted: %s\n' "$login"
}

setup_termux_remote_client() {
  bw_have ssh || bw_die "OpenSSH is missing. Finish the Termux on Android installer first."
  bw_ensure_dirs

  bw_warn "Install and sign in to the Tailscale Android app before testing this connection."
  bw_note "The Windows PC must be powered on and awake, and the WSL instance must be running."

  local host="${BLOODY_WRITER_WSL_HOST:-}"
  local login="${BLOODY_WRITER_WSL_USER:-}"
  local answer
  read -r -p "WSL Tailscale host or IP${host:+ [$host]}: " answer
  host="${answer:-$host}"
  read -r -p "WSL Linux username${login:+ [$login]}: " answer
  login="${answer:-$login}"
  [[ -n $host && -n $login ]] || bw_die "Both the WSL host and Linux username are required."
  [[ $host != *$'\n'* && $login != *$'\n'* ]] || bw_die "Remote values may not contain newlines."

  local remote_tma="/home/$login/.local/bin/tma"
  bw_set_zsh_setting BLOODY_WRITER_WSL_HOST "$host"
  bw_set_zsh_setting BLOODY_WRITER_WSL_USER "$login"
  bw_set_zsh_setting BLOODY_WRITER_WSL_TMA "$remote_tma"

  printf '\nTermux on Android is configured for the WSL workstation.\n\n'
  printf 'Start or reload Zsh, then run:\n\n  wsl-writer\n\n'
  printf 'That command opens tma in WSL, where Enter attaches and Ctrl-X safely kills a selected session.\n'
}

case "$BW_PLATFORM" in
wsl) setup_wsl_remote_host ;;
termux) setup_termux_remote_client ;;
*) bw_die "Remote setup supports Arch Linux on Windows WSL or Termux on Android." ;;
esac
