#!/usr/bin/env bash

if [[ -n ${BLOODY_WRITER_COMMON_LOADED:-} ]]; then
  return 0
fi
readonly BLOODY_WRITER_COMMON_LOADED=1

BW_REPO_ROOT="${BW_REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
BW_STATE_DIR="${BW_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/bloody-writer}"
BW_CONFIG_DIR="${BW_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/bloody-writer}"
BW_CACHE_DIR="${BW_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/bloody-writer}"
BW_DRY_RUN="${BW_DRY_RUN:-0}"
BW_ASSUME_YES="${BW_ASSUME_YES:-0}"
BW_FORCE="${BW_FORCE:-0}"
BW_TEST_MODE="${BW_TEST_MODE:-0}"

# shellcheck disable=SC1091
source "$BW_REPO_ROOT/versions.env"

if [[ -t 1 ]]; then
  BW_RED=$'\e[38;2;255;51;77m'
  BW_DIM=$'\e[38;2;223;160;160m'
  BW_RESET=$'\e[0m'
else
  BW_RED=""
  BW_DIM=""
  BW_RESET=""
fi

bw_log() {
  printf '%s==>%s %s\n' "$BW_RED" "$BW_RESET" "$*"
}

bw_note() {
  printf '%s    %s%s\n' "$BW_DIM" "$*" "$BW_RESET"
}

bw_warn() {
  printf '%sWARNING:%s %s\n' "$BW_RED" "$BW_RESET" "$*" >&2
}

bw_die() {
  printf '%sERROR:%s %s\n' "$BW_RED" "$BW_RESET" "$*" >&2
  exit 1
}

bw_quote_command() {
  printf ' %q' "$@"
  printf '\n'
}

bw_run() {
  if [[ $BW_DRY_RUN == 1 ]]; then
    printf '%sDRY RUN:%s' "$BW_DIM" "$BW_RESET"
    bw_quote_command "$@"
    return 0
  fi
  "$@"
}

bw_confirm() {
  local prompt="$1"
  if [[ $BW_ASSUME_YES == 1 ]]; then
    bw_note "$prompt [automatic yes]"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    bw_die "$prompt Re-run interactively or pass --yes."
  fi
  local answer
  read -r -p "$prompt [y/N] " answer
  [[ $answer == [Yy] || $answer == [Yy][Ee][Ss] ]]
}

bw_confirm_manual() {
  local prompt="$1"
  if [[ ! -t 0 ]]; then
    bw_warn "$prompt Confirmation must be entered interactively."
    return 1
  fi
  local answer
  read -r -p "$prompt [y/N] " answer
  [[ $answer == [Yy] || $answer == [Yy][Ee][Ss] ]]
}

bw_have() {
  command -v "$1" >/dev/null 2>&1
}

bw_is_termux() {
  [[ ${PREFIX:-${TERMUX__PREFIX:-}} == */com.termux/files/usr ]]
}

bw_is_wsl() {
  [[ -n ${WSL_DISTRO_NAME:-} ]] || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

bw_is_arch() {
  [[ -r /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ ${ID:-} == arch ]]
}

bw_detect_platform() {
  if bw_is_termux; then
    printf 'termux\n'
  elif bw_is_wsl; then
    printf 'wsl\n'
  else
    printf 'unsupported\n'
  fi
}

BW_PLATFORM="${BW_PLATFORM:-$(bw_detect_platform)}"
export BW_PLATFORM

bw_platform_label() {
  case "$BW_PLATFORM" in
  wsl) printf 'Arch Linux on Windows WSL 2\n' ;;
  termux) printf 'Termux on Android\n' ;;
  *) printf 'unsupported platform\n' ;;
  esac
}

bw_banner() {
  printf '%s' "$BW_RED"
  cat <<'EOF'
               ╱╲
              ╱  ╲
             ╱  ▸ ╲
            ╱   │  ╲
           ╱____◆___╲
EOF
  printf '         %sBLOODY WRITER%s\n' "$BW_RED" "$BW_RESET"
  printf '%s     write boldly. resume safely.%s\n\n' "$BW_DIM" "$BW_RESET"
}

bw_ensure_dirs() {
  bw_run mkdir -p \
    "$BW_STATE_DIR/completed" \
    "$BW_STATE_DIR/manual" \
    "$BW_CONFIG_DIR" \
    "$BW_CACHE_DIR" \
    "$BW_STATE_DIR/backups"
}

bw_manual_marker() {
  local checkpoint="$1"
  [[ $checkpoint =~ ^[a-z0-9][a-z0-9-]*$ ]] || bw_die "Invalid checkpoint: $checkpoint"
  printf '%s/manual/%s\n' "$BW_STATE_DIR" "$checkpoint"
}

bw_manual_pending() {
  [[ -f $(bw_manual_marker "$1") ]]
}

bw_mark_manual_pending() {
  local checkpoint="$1"
  local message="$2"
  local marker
  marker="$(bw_manual_marker "$checkpoint")"
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Would pause at manual checkpoint: $checkpoint"
    return 0
  fi
  printf '%s\n' "$message" >"$marker"
}

bw_clear_manual() {
  local marker
  marker="$(bw_manual_marker "$1")"
  [[ -e $marker ]] || return 0
  bw_run rm -- "$marker"
}

bw_phase_marker() {
  printf '%s/completed/%s\n' "$BW_STATE_DIR" "$1"
}

bw_phase_done() {
  [[ -f $(bw_phase_marker "$1") ]]
}

bw_mark_phase() {
  local phase="$1"
  local marker
  marker="$(bw_phase_marker "$phase")"
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Would mark phase $phase complete."
    return 0
  fi
  {
    printf 'completed_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'version=%s\n' "$BLOODY_WRITER_VERSION"
    printf 'platform=%s\n' "$BW_PLATFORM"
    if git -C "$BW_REPO_ROOT" rev-parse HEAD >/dev/null 2>&1; then
      printf 'commit=%s\n' "$(git -C "$BW_REPO_ROOT" rev-parse HEAD)"
    fi
  } >"$marker"
}

bw_clear_phase() {
  local marker
  marker="$(bw_phase_marker "$1")"
  [[ -e $marker ]] || return 0
  bw_run rm -- "$marker"
}

bw_begin_backup() {
  if [[ -n ${BW_BACKUP_DIR:-} ]]; then
    return 0
  fi
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S-%N)"
  BW_BACKUP_DIR="$BW_STATE_DIR/backups/$stamp"
  export BW_BACKUP_DIR
  bw_run mkdir -p "$BW_BACKUP_DIR"
  if [[ $BW_DRY_RUN != 1 ]]; then
    : >"$BW_BACKUP_DIR/manifest.tsv"
  fi
}

bw_validate_home_target() {
  local target="$1"
  case "$target" in
  "$HOME" | "$HOME"/*) ;;
  *) bw_die "Refusing to manage a path outside HOME: $target" ;;
  esac
}

bw_backup_path() {
  local target="$1"
  bw_validate_home_target "$target"
  [[ -e $target || -L $target ]] || return 0
  bw_begin_backup
  local relative destination
  relative="${target#"$HOME"/}"
  destination="$BW_BACKUP_DIR/$relative"
  bw_log "Backing up $target"
  bw_run mkdir -p "$(dirname -- "$destination")"
  bw_run mv -- "$target" "$destination"
  if [[ $BW_DRY_RUN != 1 ]]; then
    printf '%s\t%s\n' "$target" "$destination" >>"$BW_BACKUP_DIR/manifest.tsv"
  fi
}

bw_link_managed() {
  local source="$1"
  local target="$2"
  bw_validate_home_target "$target"
  [[ -e $source || -L $source ]] || bw_die "Managed source is missing: $source"

  if [[ -L $target ]] && [[ $(readlink -f -- "$target") == "$(readlink -f -- "$source")" ]]; then
    bw_note "Already linked: $target"
    return 0
  fi

  if [[ -e $target || -L $target ]]; then
    bw_backup_path "$target"
  else
    bw_begin_backup
    if [[ $BW_DRY_RUN != 1 ]]; then
      printf '%s\t%s\n' "$target" "__MISSING__" >>"$BW_BACKUP_DIR/manifest.tsv"
    fi
  fi

  bw_log "Linking $target"
  bw_run mkdir -p "$(dirname -- "$target")"
  bw_run ln -s -- "$source" "$target"
}

bw_write_if_missing() {
  local target="$1"
  local source="$2"
  bw_validate_home_target "$target"
  if [[ -e $target ]]; then
    bw_note "Preserving existing file: $target"
    return 0
  fi
  bw_run mkdir -p "$(dirname -- "$target")"
  bw_run cp -- "$source" "$target"
}

bw_set_zsh_setting() {
  local key="$1"
  local value="$2"
  local settings="$BW_CONFIG_DIR/settings.zsh"
  [[ $key =~ ^[A-Z][A-Z0-9_]*$ ]] || bw_die "Invalid setting name: $key"
  [[ $value != *$'\n'* && $value != *"'"* ]] || bw_die "Setting contains unsupported characters: $key"
  bw_run mkdir -p "$BW_CONFIG_DIR"
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Would set $key in $settings."
    return 0
  fi
  local temporary
  temporary="$(mktemp "$BW_CONFIG_DIR/.settings.XXXXXX")"
  if [[ -f $settings ]]; then
    awk -v key="$key" '$0 !~ "^export " key "=" { print }' "$settings" >"$temporary"
  fi
  printf "export %s='%s'\n" "$key" "$value" >>"$temporary"
  chmod 600 "$temporary"
  mv -- "$temporary" "$settings"
}

bw_repo_commit() {
  git -C "$BW_REPO_ROOT" rev-parse --short HEAD 2>/dev/null || printf 'uncommitted'
}
