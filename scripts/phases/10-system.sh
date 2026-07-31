#!/usr/bin/env bash

phase_10_system() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  local init_name
  init_name="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"

  if [[ -f $BW_STATE_DIR/restart-required && $init_name == systemd ]]; then
    bw_log "The requested WSL restart was detected."
    bw_run rm -- "$BW_STATE_DIR/restart-required"
  fi

  local desired current temporary
  desired=$'[boot]\nsystemd=true\n\n[user]\ndefault='"$USER"$'\n\n[interop]\nenabled=true\nappendWindowsPath=true\n'
  current="$(cat /etc/wsl.conf 2>/dev/null || true)"

  if [[ "$current"$'\n' != "$desired" ]]; then
    bw_warn "/etc/wsl.conf must be updated to enable systemd and make $USER the default user."
    bw_confirm "Back up and replace /etc/wsl.conf with the documented Bloody Writer baseline?" || return 1
    temporary="$(mktemp "$BW_CACHE_DIR/wsl.conf.XXXXXX")"
    printf '%s' "$desired" >"$temporary"
    if [[ -f /etc/wsl.conf ]]; then
      bw_run sudo cp -- /etc/wsl.conf "/etc/wsl.conf.before-bloody-writer-$(date +%Y%m%d-%H%M%S)"
    fi
    bw_run sudo install -m 0644 "$temporary" /etc/wsl.conf
    bw_run rm -- "$temporary"
    if [[ $BW_DRY_RUN != 1 ]]; then
      printf '%s\n' "system configuration changed" >"$BW_STATE_DIR/restart-required"
    fi

    printf '\nRun these commands from Windows PowerShell:\n\n'
    printf '  wsl --terminate %q\n' "${WSL_DISTRO_NAME:-archlinux}"
    printf '  wsl --distribution %q\n\n' "${WSL_DISTRO_NAME:-archlinux}"
    printf 'Then return to the repository and run:\n\n  ./install.sh\n\n'
    return 20
  fi

  if [[ $init_name != systemd ]]; then
    if [[ $BW_DRY_RUN == 1 ]]; then
      bw_note "A real run would require a WSL restart because PID 1 is $init_name."
      return 0
    fi
    printf '%s\n' "systemd is not PID 1" >"$BW_STATE_DIR/restart-required"
    printf 'Systemd is configured but not active. From Windows PowerShell run:\n\n'
    printf '  wsl --terminate %q\n' "${WSL_DISTRO_NAME:-archlinux}"
    printf '  wsl --distribution %q\n\n' "${WSL_DISTRO_NAME:-archlinux}"
    printf 'Then rerun ./install.sh.\n'
    return 20
  fi

  if ! grep -q '^en_US.UTF-8 UTF-8$' /etc/locale.gen 2>/dev/null ||
    ! grep -q '^es_ES.UTF-8 UTF-8$' /etc/locale.gen 2>/dev/null; then
    bw_log "Enabling English and Spanish UTF-8 locales."
    bw_run sudo sed -i \
      -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
      -e 's/^#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' \
      /etc/locale.gen
    bw_run sudo locale-gen
  fi

  if [[ $(cat /etc/locale.conf 2>/dev/null || true) != "LANG=en_US.UTF-8" ]]; then
    temporary="$(mktemp "$BW_CACHE_DIR/locale.conf.XXXXXX")"
    printf 'LANG=en_US.UTF-8\n' >"$temporary"
    bw_run sudo install -m 0644 "$temporary" /etc/locale.conf
    bw_run rm -- "$temporary"
  fi
}
