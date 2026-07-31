#!/usr/bin/env bash

phase_30_shell() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  local omz="$HOME/.oh-my-zsh"
  local current_commit=""
  if [[ -d $omz/.git ]]; then
    current_commit="$(git -C "$omz" rev-parse HEAD 2>/dev/null || true)"
  fi

  if [[ $current_commit == "$OH_MY_ZSH_COMMIT" ]] &&
    [[ -z $(git -C "$omz" status --porcelain 2>/dev/null) ]]; then
    bw_note "Oh My Zsh is already at the tracked commit."
  else
    if [[ -e $omz || -L $omz ]]; then
      bw_warn "The existing Oh My Zsh directory differs from the tracked snapshot."
      bw_confirm "Back it up and install the tracked Oh My Zsh commit?" || return 1
      bw_backup_path "$omz"
    fi
    bw_log "Installing Oh My Zsh at $OH_MY_ZSH_COMMIT."
    bw_run git clone --filter=blob:none https://github.com/ohmyzsh/ohmyzsh.git "$omz"
    bw_run git -C "$omz" checkout --detach "$OH_MY_ZSH_COMMIT"
  fi

  local current_shell
  current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ $current_shell != /usr/bin/zsh ]]; then
    bw_log "Setting Zsh as the login shell."
    bw_run sudo usermod --shell /usr/bin/zsh "$USER"
  fi
}
