#!/usr/bin/env bash

phase_60_codex() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  if [[ $BW_PLATFORM == termux ]]; then
    bw_warn "OpenAI does not publish a native Android Codex CLI build. Bloody Writer will not install an unofficial binary."
    bw_note "Use the supported Codex installation in Windows WSL from Termux on Android: run 'bloody-writer remote'."
    return 0
  fi

  local codex_bin="$HOME/.local/bin/codex"
  local installed_version=""
  if [[ -x $codex_bin ]]; then
    installed_version="$(env CODEX_HOME="$HOME/.codex" "$codex_bin" --version 2>/dev/null | awk '{print $2}')"
  fi

  if [[ $installed_version != "$CODEX_VERSION" ]]; then
    local installer="$BW_CACHE_DIR/codex-install.sh"
    bw_log "Downloading OpenAI's official Codex installer."
    bw_run curl -fsSL https://chatgpt.com/codex/install.sh -o "$installer"
    [[ $BW_DRY_RUN == 1 ]] || sh -n "$installer"
    bw_log "Installing Codex $CODEX_VERSION into the Linux user profile."
    bw_run env CODEX_HOME="$HOME/.codex" CODEX_NON_INTERACTIVE=true PATH="$HOME/.local/bin:$PATH" \
      sh "$installer" --release "$CODEX_VERSION"
  else
    bw_note "Codex $CODEX_VERSION is already installed."
  fi

  local config_template="$BW_REPO_ROOT/templates/codex-config.toml"
  bw_write_if_missing "$HOME/.codex/config.toml" "$config_template"

  if [[ $BW_SKIP_CODEX_LOGIN == 1 ]]; then
    bw_note "Codex login was skipped by request."
    return 0
  fi

  if env CODEX_HOME="$HOME/.codex" "$codex_bin" login status >/dev/null 2>&1; then
    bw_note "Codex authentication is already configured."
  elif [[ -t 0 ]]; then
    bw_log "Starting Codex device authentication. Credentials remain outside this repository."
    bw_run env CODEX_HOME="$HOME/.codex" "$codex_bin" login --device-auth
  else
    bw_warn "Codex is installed but not authenticated. Run: CODEX_HOME=\$HOME/.codex codex login --device-auth"
  fi
}
