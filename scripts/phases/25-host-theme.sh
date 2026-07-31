#!/usr/bin/env bash

phase_25_host_theme() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  case "$BW_PLATFORM" in
  wsl) phase_25_windows_terminal ;;
  termux) phase_25_termux_android ;;
  *) bw_die "Host-theme phase does not support: $BW_PLATFORM" ;;
  esac
}

phase_25_windows_terminal() {
  local checkpoint="windows-terminal-restart"
  if bw_manual_pending "$checkpoint"; then
    bw_warn "Windows Terminal must be reopened before the new font and profile are visible."
    if bw_confirm_manual "Have you closed every Windows Terminal window and reopened Bloody Writer - Arch WSL?"; then
      bw_clear_manual "$checkpoint"
      return 0
    fi
    bw_note "Installation remains paused. Reopen the terminal and run ./install.sh again."
    return 20
  fi

  bw_warn "This phase installs a current-user Nerd Font and a separate Windows Terminal profile."
  bw_note "It does not rewrite settings.json or modify your existing terminal profiles."
  bw_confirm "Install the Bloody Writer Windows Terminal host layer?" || return 1

  bw_have powershell.exe || bw_die "powershell.exe is required for the Windows host layer."
  bw_have wslpath || bw_die "wslpath is required for the Windows host layer."
  local script_path distro_name
  script_path="$(wslpath -w "$BW_REPO_ROOT/windows/apply-host-theme.ps1")"
  distro_name="${WSL_DISTRO_NAME:-archlinux}"
  bw_run powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass \
    -File "$script_path" -DistroName "$distro_name"

  if [[ $BW_DRY_RUN == 1 ]]; then
    return 0
  fi
  bw_mark_manual_pending "$checkpoint" \
    "Close every Windows Terminal window, reopen Bloody Writer - Arch WSL, then rerun ./install.sh."
  printf '\nThe Windows host files are installed, but Terminal must reload them.\n\n'
  printf '1. Close every Windows Terminal window.\n'
  printf '2. Reopen Windows Terminal.\n'
  printf '3. Select: Bloody Writer - Arch WSL\n'
  printf '4. Return to this repository and run: ./install.sh\n\n'
  return 20
}

phase_25_termux_android() {
  local storage_checkpoint="termux-storage-permission"
  if [[ ! -d $HOME/storage/shared ]]; then
    bw_warn "Android shared storage permission is required for the Writer Documents workflow."
    bw_log "Opening Android's Termux storage permission flow."
    bw_run termux-setup-storage
    if [[ $BW_DRY_RUN == 1 ]]; then
      bw_note "Would verify Android shared storage after the permission flow."
    elif [[ ! -d $HOME/storage/shared ]]; then
      bw_mark_manual_pending "$storage_checkpoint" \
        "Grant Termux file access in Android, return to Termux, and rerun ./install.sh."
      printf '\nInstallation paused for Android permission.\n\n'
      printf 'Grant the Termux file-access prompt, return here, and run: ./install.sh\n\n'
      return 20
    fi
  fi
  bw_clear_manual "$storage_checkpoint"

  local api_checkpoint="termux-api-app"
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Would verify the matching-source Termux:API Android companion app."
  elif ! timeout 5 termux-clipboard-get >/dev/null 2>&1; then
    bw_mark_manual_pending "$api_checkpoint" \
      "Install the Termux:API Android app from the same source as Termux, then rerun ./install.sh."
    printf '\nInstallation paused for Termux:API.\n\n'
    printf 'Install the Termux:API Android app from the same source as the main Termux app.\n'
    printf 'Do not mix F-Droid and GitHub-signed Termux applications.\n'
    printf 'After installing it, return here and run: ./install.sh\n\n'
    return 20
  fi
  bw_clear_manual "$api_checkpoint"

  local termux_dir="$HOME/.termux"
  local font="$termux_dir/font.ttf"
  local font_url
  local font_actual
  font_url="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v${NERD_FONT_VERSION}/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFontMono-Regular.ttf"
  font_actual="$(sha256sum "$font" 2>/dev/null | awk '{print $1}' || true)"
  bw_run mkdir -p "$termux_dir"
  if [[ $font_actual != "$NERD_FONT_SHA256" ]]; then
    local font_download="$BW_CACHE_DIR/JetBrainsMonoNerdFontMono-Regular.ttf"
    bw_log "Downloading the pinned JetBrains Mono Nerd Font for Termux."
    bw_run curl -fsSL "$font_url" -o "$font_download"
    if [[ $BW_DRY_RUN != 1 ]]; then
      font_actual="$(sha256sum "$font_download" | awk '{print $1}')"
      [[ $font_actual == "$NERD_FONT_SHA256" ]] || bw_die "Nerd Font checksum verification failed."
    fi
    bw_run install -m 0644 "$font_download" "$font"
  fi

  bw_link_managed \
    "$BW_REPO_ROOT/terminal/termux/colors.properties" \
    "$termux_dir/colors.properties"
  bw_run termux-reload-settings
  bw_run mkdir -p "$HOME/storage/shared/Documents"
  bw_set_zsh_setting BLOODY_WRITER_DOCUMENTS "$HOME/storage/shared/Documents"
  bw_note "Termux colors, font, Android clipboard, and shared Documents access are ready."
}
