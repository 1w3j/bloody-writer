#!/usr/bin/env bash

phase_70_github() {
  [[ $BW_TEST_MODE == 1 ]] && return 0
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Would configure Git identity, GitHub authentication, a dedicated SSH key, and keychain."
    return 0
  fi

  if ! gh auth status >/dev/null 2>&1; then
    [[ -t 0 ]] || bw_die "GitHub authentication needs an interactive terminal. Re-run this phase later."
    bw_log "Starting GitHub's browser-based authentication."
    bw_run gh auth login --web --git-protocol ssh --skip-ssh-key --scopes admin:public_key
  fi

  local login user_id default_name default_email git_name git_email
  login="$(gh api user --jq .login)"
  user_id="$(gh api user --jq .id)"
  default_name="$(gh api user --jq '.name // .login')"
  default_email="${user_id}+${login}@users.noreply.github.com"
  git_name="$(git config --global user.name || true)"
  git_email="$(git config --global user.email || true)"

  if [[ -z $git_name ]]; then
    if [[ $BW_ASSUME_YES == 1 ]]; then
      git_name="$default_name"
    else
      read -r -p "Git commit name [$default_name]: " git_name
      git_name="${git_name:-$default_name}"
    fi
    bw_run git config --global user.name "$git_name"
  fi

  if [[ -z $git_email ]]; then
    if [[ $BW_ASSUME_YES == 1 ]]; then
      git_email="$default_email"
    else
      read -r -p "Git commit email [$default_email]: " git_email
      git_email="${git_email:-$default_email}"
    fi
    bw_run git config --global user.email "$git_email"
  fi
  bw_run git config --global init.defaultBranch main

  local key="$HOME/.ssh/id_ed25519_github_${login}"
  bw_run mkdir -p "$HOME/.ssh"
  [[ $BW_DRY_RUN == 1 ]] || chmod 700 "$HOME/.ssh"
  if [[ ! -f $key ]]; then
    bw_log "Creating a dedicated GitHub SSH key. Choose a passphrase when prompted."
    bw_run ssh-keygen -t ed25519 -C "$git_email" -f "$key"
  else
    bw_note "Preserving existing GitHub SSH key: $key"
  fi
  if [[ ! -f $key.pub ]]; then
    local public_key_temporary
    public_key_temporary="$(mktemp "$HOME/.ssh/.github-key.XXXXXX")"
    bw_log "Rebuilding the missing public half of the existing GitHub SSH key."
    ssh-keygen -y -f "$key" >"$public_key_temporary"
    chmod 0644 "$public_key_temporary"
    mv -- "$public_key_temporary" "$key.pub"
  fi

  local ssh_config="$HOME/.ssh/config"
  if ! grep -q '^[[:space:]]*Host[[:space:]].*github\.com' "$ssh_config" 2>/dev/null; then
    bw_log "Adding a GitHub host entry to ~/.ssh/config."
    if [[ $BW_DRY_RUN != 1 ]]; then
      {
        printf '\n# BEGIN BLOODY WRITER GITHUB\n'
        printf 'Host github.com\n'
        printf '  HostName github.com\n'
        printf '  User git\n'
        printf '  IdentityFile %s\n' "$key"
        printf '  IdentitiesOnly yes\n'
        printf '  AddKeysToAgent yes\n'
        printf '# END BLOODY WRITER GITHUB\n'
      } >>"$ssh_config"
      chmod 600 "$ssh_config"
    fi
  else
    bw_note "Preserving the existing github.com SSH host configuration."
  fi

  local public_material registered_keys
  public_material="$(awk '{ print $1 " " $2 }' "$key.pub")"
  if ! registered_keys="$(gh api user/keys --jq '.[].key' 2>/dev/null)"; then
    bw_log "GitHub needs permission to manage the public SSH key."
    bw_run gh auth refresh --hostname github.com --scopes admin:public_key
    registered_keys="$(gh api user/keys --jq '.[].key')"
  fi
  if ! printf '%s\n' "$registered_keys" |
    awk '{ print $1 " " $2 }' |
    grep -Fxq "$public_material"; then
    bw_log "Registering the public SSH key with GitHub."
    bw_run gh ssh-key add "$key.pub" --title "Bloody Writer - $(hostname) - $(date +%Y-%m-%d)"
  fi

  bw_set_zsh_setting BLOODY_WRITER_GITHUB_KEY "$key"
  if [[ $BW_DRY_RUN != 1 ]]; then
    eval "$(keychain --eval --quiet "$(basename -- "$key")")"
  fi
}
