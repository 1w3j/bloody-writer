#!/usr/bin/env bash

phase_00_preflight() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  case "$BW_PLATFORM" in
  wsl)
    grep -qi 'wsl2' /proc/sys/kernel/osrelease 2>/dev/null || bw_die "WSL 2 is required."
    bw_is_arch || bw_die "The WSL path supports the official Arch Linux distribution."
    bw_have sudo || bw_die "sudo is required. Fresh Arch WSL root sessions should run scripts/bootstrap-root.sh first."
    [[ $BW_DRY_RUN == 1 ]] || sudo -v
    ;;
  termux)
    bw_have pkg || bw_die "Termux package management is missing. Install a current Termux build from F-Droid or GitHub."
    [[ ${PREFIX:-} == */com.termux/files/usr ]] || bw_die "The Android path must run in the main Termux environment."
    ;;
  *)
    bw_die "Unsupported platform. Use Arch Linux on Windows WSL 2 or the Termux app on Android."
    ;;
  esac

  ((EUID != 0)) || bw_die "Run the installer as your normal user, not root."
  [[ -n ${HOME:-} && -d $HOME ]] || bw_die "HOME is not a usable directory."
  [[ $HOME != /root ]] || bw_die "A normal user account is required."
  [[ -r $BW_REPO_ROOT/versions.env ]] || bw_die "Repository files are incomplete."
  bw_have bash || bw_die "bash is required."

  bw_note "User: ${USER:-$(id -un)}"
  bw_note "Platform: $(bw_platform_label)"
  bw_note "Repository: $BW_REPO_ROOT"
}
