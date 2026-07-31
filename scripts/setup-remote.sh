#!/usr/bin/env bash
set -Eeuo pipefail

BW_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
export BW_REPO_ROOT
# shellcheck disable=SC1091
source "$BW_REPO_ROOT/scripts/lib/common.sh"

bw_is_wsl || bw_die "Remote setup is intended for WSL."
bw_is_arch || bw_die "Remote setup is intended for Arch Linux."
[[ $(ps -p 1 -o comm= | tr -d '[:space:]') == systemd ]] ||
  bw_die "systemd must be active. Finish the normal installer and restart WSL first."

bw_warn "Remote access requires the Windows PC to remain powered on, awake, and running WSL."
bw_confirm "Install Tailscale and enable private Tailscale SSH access?" || exit 0

sudo pacman -S --needed tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up --ssh

tailscale_name="$(tailscale status --self --json 2>/dev/null | jq -r '.Self.DNSName // empty' | sed 's/\.$//')"
tailscale_ip="$(tailscale ip -4 2>/dev/null | head -n 1)"

printf '\nRemote access is ready on the WSL side.\n\n'
printf '1. Install Tailscale on Android and sign in to the same tailnet.\n'
printf '2. In Termux install OpenSSH: pkg install openssh\n'
if [[ -n $tailscale_name ]]; then
  printf '3. Connect and choose a tmux session:\n\n   ssh -t %s@%s /home/%s/.local/bin/tma\n' \
    "$USER" "$tailscale_name" "$USER"
else
  printf '3. Connect and choose a tmux session:\n\n   ssh -t %s@%s /home/%s/.local/bin/tma\n' \
    "$USER" "$tailscale_ip" "$USER"
fi
printf '\nSee docs/REMOTE-ACCESS.md for phone aliases, wake limitations, and troubleshooting.\n'
