#!/usr/bin/env bash

phase_40_dotfiles() {
  bw_link_managed "$BW_REPO_ROOT/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
  bw_link_managed "$BW_REPO_ROOT/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
  bw_link_managed "$BW_REPO_ROOT/dotfiles/nvim/.config/nvim" "$HOME/.config/nvim"
  bw_link_managed "$BW_REPO_ROOT/dotfiles/local-bin/.local/bin/tma" "$HOME/.local/bin/tma"
  bw_link_managed "$BW_REPO_ROOT/bin/bloody-writer" "$HOME/.local/bin/bloody-writer"

  local settings_template="$BW_REPO_ROOT/dotfiles/zsh/settings.zsh.example"
  bw_write_if_missing "$BW_CONFIG_DIR/settings.zsh" "$settings_template"
  [[ $BW_DRY_RUN == 1 ]] || chmod 600 "$BW_CONFIG_DIR/settings.zsh"

  if [[ $BW_TEST_MODE != 1 ]] && bw_have cmd.exe && bw_have wslpath; then
    local windows_profile windows_documents
    windows_profile="$(cmd.exe /d /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r' || true)"
    if [[ -n $windows_profile ]]; then
      windows_documents="$(wslpath -u "$windows_profile" 2>/dev/null)/Documents"
      if [[ -d $windows_documents && ! -e $HOME/Documents && ! -L $HOME/Documents ]]; then
        bw_log "Linking ~/Documents to Windows Documents."
        bw_run ln -s -- "$windows_documents" "$HOME/Documents"
      fi
    fi
  fi
}
