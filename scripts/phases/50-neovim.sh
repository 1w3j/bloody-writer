#!/usr/bin/env bash

phase_50_neovim() {
  [[ $BW_TEST_MODE == 1 ]] && return 0

  local spell_dir="$HOME/.local/share/nvim/site/spell"
  bw_run mkdir -p "$spell_dir"

  local base_url="https://ftp.nluug.nl/pub/vim/runtime/spell"
  local entries=(
    "en.utf-8.spl:fecabdc949b6a39d32c0899fa2545eab25e63f2ed0a33c4ad1511426384d3070"
    "en.utf-8.sug:5b6e5e6165582d2fd7a1bfa41fbce8242c72476222c55d17c2aa2ba933c932ec"
    "es.utf-8.spl:963637ac925cf8a51bf207fac392d6b4c69795711dcc2d4809b78846ae367be3"
    "es.utf-8.sug:e70f3478aa653c2ae905086328fbff4e43bd646d76534645f50a65344801bd6c"
  )
  local entry file expected actual temporary
  for entry in "${entries[@]}"; do
    file="${entry%%:*}"
    expected="${entry#*:}"
    actual="$(sha256sum "$spell_dir/$file" 2>/dev/null | awk '{print $1}')"
    if [[ $actual == "$expected" ]]; then
      bw_note "Spell file is current: $file"
      continue
    fi
    temporary="$BW_CACHE_DIR/$file.download"
    bw_log "Downloading verified spell file: $file"
    bw_run curl -fsSL "$base_url/$file" -o "$temporary"
    if [[ $BW_DRY_RUN != 1 ]]; then
      actual="$(sha256sum "$temporary" | awk '{print $1}')"
      [[ $actual == "$expected" ]] || bw_die "Checksum verification failed for $file."
    fi
    bw_run install -m 0644 "$temporary" "$spell_dir/$file"
  done

  bw_log "Synchronizing Neovim plugins to lazy-lock.json."
  bw_run env XDG_CONFIG_HOME="$HOME/.config" nvim --headless "+Lazy! sync" +qa
  bw_run env XDG_CONFIG_HOME="$HOME/.config" nvim --headless "+checkhealth vim.lsp" +qa
}
