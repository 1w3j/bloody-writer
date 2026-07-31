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

  local current_shell zsh_path
  zsh_path="$(command -v zsh)"
  if [[ $BW_PLATFORM == termux ]]; then
    current_shell="${SHELL:-}"
    if [[ $current_shell != "$zsh_path" ]]; then
      bw_log "Setting Zsh as the Termux login shell."
      bw_run chsh -s "$zsh_path"
    fi
  else
    current_shell="$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)"
    if [[ $current_shell != "$zsh_path" ]]; then
      bw_log "Setting Zsh as the WSL login shell."
      bw_run sudo usermod --shell "$zsh_path" "${USER:-$(id -un)}"
    fi
  fi
}
