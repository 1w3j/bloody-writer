#!/usr/bin/env bash

phase_00_preflight() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  bw_is_wsl || bw_die "Bloody Writer currently supports Arch Linux running under WSL 2."
  grep -qi 'wsl2' /proc/sys/kernel/osrelease 2>/dev/null || bw_die "WSL 2 is required."
  bw_is_arch || bw_die "Bloody Writer currently supports Arch Linux only."
  ((EUID != 0)) || bw_die "Run the installer as your normal WSL user, not root."
  [[ -n ${HOME:-} && -d $HOME ]] || bw_die "HOME is not a usable directory."
  [[ $HOME != /root ]] || bw_die "A normal user account is required."
  [[ -r $BW_REPO_ROOT/versions.env ]] || bw_die "Repository files are incomplete."
  bw_have bash || bw_die "bash is required."
  bw_have sudo || bw_die "sudo is required. Fresh root sessions should run scripts/bootstrap-root.sh first."
  if [[ $BW_DRY_RUN != 1 ]]; then
    sudo -v
  fi

  bw_note "User: $USER"
  bw_note "Distro: ${WSL_DISTRO_NAME:-Arch}"
  bw_note "Repository: $BW_REPO_ROOT"
}
