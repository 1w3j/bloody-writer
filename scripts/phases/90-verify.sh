#!/usr/bin/env bash

phase_90_verify() {
  [[ $BW_TEST_MODE == 1 ]] && return 0
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Verification will run after the planned changes are applied."
    return 0
  fi

  local required=(zsh nvim tmux git gh rg fd fzf jq keychain node npm pnpm python)
  local missing=() command_name
  for command_name in "${required[@]}"; do
    bw_have "$command_name" || missing+=("$command_name")
  done
  ((${#missing[@]} == 0)) || bw_die "Required commands are missing: ${missing[*]}"

  [[ -L $HOME/.zshrc ]] || bw_die "$HOME/.zshrc is not managed by Bloody Writer."
  [[ -L $HOME/.tmux.conf ]] || bw_die "$HOME/.tmux.conf is not managed by Bloody Writer."
  [[ -L $HOME/.config/nvim ]] || bw_die "$HOME/.config/nvim is not managed by Bloody Writer."
  [[ -x $HOME/.local/bin/codex ]] || bw_die "The Linux Codex executable is missing."
  [[ -x $HOME/.local/bin/tma ]] || bw_die "The tmux picker is missing."
  [[ -x $HOME/.local/bin/bloody-writer ]] || bw_die "The Bloody Writer command is missing."

  bw_run zsh -n "$HOME/.zshrc"
  local tmux_socket="bloody-writer-verify-$$"
  bw_run tmux -f "$HOME/.tmux.conf" -L "$tmux_socket" new-session -d -s verify
  bw_run tmux -L "$tmux_socket" kill-server
  bw_run env XDG_CONFIG_HOME="$HOME/.config" nvim --headless "+lua require('writer.theme').setup()" +qa

  bw_log "Installed versions"
  zsh --version
  nvim --version | head -n 1
  tmux -V
  env CODEX_HOME="$HOME/.codex" "$HOME/.local/bin/codex" --version
}
