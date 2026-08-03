# Bloody Writer — portable shell configuration for Windows WSL and Android Termux
export ZSH="$HOME/.oh-my-zsh"

# Bloody Writer installs its user commands here on both WSL and Termux. Zsh's tied `path`
# array keeps the directory first and removes duplicates when this file is reloaded.
typeset -U path PATH
path=("$HOME/.local/bin" $path)
export PATH

ZSH_THEME="agnoster"
plugins=(
  git
  z
  extract
  colored-man-pages
  command-not-found
)
(( $+commands[sudo] )) && plugins+=(sudo)

HIST_STAMPS="yyyy-mm-dd"
DISABLE_MAGIC_FUNCTIONS=true
zstyle ':omz:update' mode disabled

# Agnoster compares against Zsh's special USERNAME parameter. Android's generated Termux account
# name is not guaranteed to match the inherited USER environment variable.
DEFAULT_USER="${USERNAME:-${USER:-$(id -un)}}"

source "$ZSH/oh-my-zsh.sh"

# Bloody-red Agnoster directory segment: ANSI red background, white text.
prompt_dir() {
  prompt_segment 1 15 '%~'
}

settings_file="${XDG_CONFIG_HOME:-$HOME/.config}/bloody-writer/settings.zsh"
[[ -r $settings_file ]] && source "$settings_file"
unset settings_file

export EDITOR="nvim"
export VISUAL="nvim"
export WRITER_DOCUMENTS="${BLOODY_WRITER_DOCUMENTS:-$HOME/Documents}"

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias tree='tree -C --dirsfirst -F'
alias v='nvim'
alias vim='nvim'
alias ta='tma'
alias tn='tmux new-session -A -s writer'

writer() {
  if [[ ! -d $WRITER_DOCUMENTS ]]; then
    printf 'Writer directory does not exist: %s\n' "$WRITER_DOCUMENTS" >&2
    return 1
  fi
  cd "$WRITER_DOCUMENTS" && nvim
}

wsl-writer() {
  if [[ -z ${BLOODY_WRITER_WSL_HOST:-} || -z ${BLOODY_WRITER_WSL_USER:-} ]]; then
    printf 'Remote WSL is not configured. Run: bloody-writer remote\n' >&2
    return 1
  fi
  local remote_tma="${BLOODY_WRITER_WSL_TMA:-/home/$BLOODY_WRITER_WSL_USER/.local/bin/tma}"
  ssh -t -- "$BLOODY_WRITER_WSL_USER@$BLOODY_WRITER_WSL_HOST" "$remote_tma"
}

# Reuse one passphrase-unlocked GitHub key across terminals and tmux clients.
if [[ -n ${BLOODY_WRITER_GITHUB_KEY:-} && -f $BLOODY_WRITER_GITHUB_KEY ]]; then
  eval "$(keychain --eval --quiet "$(basename -- "$BLOODY_WRITER_GITHUB_KEY")")"
fi
