#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
BW_REPO_ROOT="$repo_root"
export BW_REPO_ROOT
# shellcheck disable=SC1091
source "$BW_REPO_ROOT/scripts/lib/common.sh"

if ((EUID != 0)); then
  printf 'This bootstrap is only for the initial root shell of a fresh Arch WSL instance.\n' >&2
  exit 1
fi

if ! grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  printf 'Bloody Writer root bootstrap supports WSL only.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != arch ]]; then
  printf 'Bloody Writer root bootstrap supports Arch Linux only.\n' >&2
  exit 1
fi

bw_banner
printf 'Fresh Arch Linux on Windows WSL user bootstrap\n\n'
read -r -p 'New Linux username: ' target_user
if [[ ! $target_user =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  printf 'Use a lowercase Linux username containing letters, digits, underscores, or hyphens.\n' >&2
  exit 1
fi
if [[ $target_user == root ]]; then
  printf 'The normal user cannot be root.\n' >&2
  exit 1
fi

pacman -Syu --needed base-devel curl git sudo zsh

if ! id "$target_user" >/dev/null 2>&1; then
  useradd --create-home --groups wheel --shell /usr/bin/zsh "$target_user"
  printf 'Create the Linux password for %s:\n' "$target_user"
  passwd "$target_user"
else
  usermod --append --groups wheel --shell /usr/bin/zsh "$target_user"
fi

install -d -m 0750 /etc/sudoers.d
printf '%%wheel ALL=(ALL:ALL) ALL\n' >/etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo --check

if [[ -f /etc/wsl.conf ]]; then
  cp -- /etc/wsl.conf "/etc/wsl.conf.before-bloody-writer-$(date +%Y%m%d-%H%M%S)"
fi
cat >/etc/wsl.conf <<EOF
[boot]
systemd=true

[user]
default=$target_user

[interop]
enabled=true
appendWindowsPath=true
EOF

target_repo="/home/$target_user/bloody-writer"
if [[ $repo_root != "$target_repo" ]]; then
  if [[ -e $target_repo ]]; then
    printf 'Preserving existing target repository: %s\n' "$target_repo"
  else
    cp -a -- "$repo_root" "$target_repo"
  fi
  chown -R "$target_user:$target_user" "$target_repo"
fi

printf '\nInitial user setup is complete.\n\n'
printf 'From Windows PowerShell, run:\n\n'
printf '  wsl --terminate %q\n' "${WSL_DISTRO_NAME:-archlinux}"
printf '  wsl --distribution %q\n\n' "${WSL_DISTRO_NAME:-archlinux}"
printf 'Then, as %s:\n\n' "$target_user"
printf '  cd ~/bloody-writer\n'
printf '  ./install.sh\n\n'
