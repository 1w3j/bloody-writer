#!/usr/bin/env bash

if [[ -n ${BLOODY_WRITER_WORKSPACE_LOADED:-} ]]; then
  return 0
fi
readonly BLOODY_WRITER_WORKSPACE_LOADED=1

readonly BW_WORKSPACE_MAX_BYTES=1048576
readonly BW_WORKSPACE_PHASES=(
  "workspace-packages"
  "workspace-system-files"
  "workspace-project-setup"
  "workspace-verify"
)

BW_WORKSPACE_FILE="${BW_WORKSPACE_FILE:-}"
BW_WORKSPACE_ROOT="${BW_WORKSPACE_ROOT:-}"
BW_WORKSPACE_ID="${BW_WORKSPACE_ID:-}"
BW_WORKSPACE_DIGEST="${BW_WORKSPACE_DIGEST:-}"
BW_WORKSPACE_GENERATION="${BW_WORKSPACE_GENERATION:-}"

bw_workspace_usage() {
  cat <<'EOF'
Bloody Writer workspace profiles — reproducible project tools on Arch Linux WSL 2

Usage:
  bloody-writer install --workspace FILE [install options]
  bloody-writer install -w FILE [install options]
  bloody-writer workspace scan --project DIR --output FILE
  bloody-writer workspace validate FILE
  bloody-writer workspace audit FILE
  bloody-writer workspace apply FILE [--yes] [--dry-run] [--force]
  bloody-writer workspace status
  bloody-writer workspace resume [--yes] [--dry-run] [--force]
  bloody-writer workspace help

What these commands do:
  scan      Create a deterministic candidate profile from safe, reproducible project surfaces.
  validate  Strictly check an approved, Git-tracked profile without changing the machine.
  audit     Compare an approved profile with the current WSL workstation.
  apply     Install only the workspace layer after the Bloody Writer base is complete.
  status    Show the active profile, digest, and resumable workspace phases.
  resume    Continue the active profile at its first incomplete phase.

Safety:
  Workspace profiles are WSL-only. Termux on Android, root, non-Arch WSL, candidate profiles,
  untracked sources, unsafe paths, and unknown JSON keys are rejected. Commands are argument
  arrays and are never sourced or evaluated by a shell. Credentials and runtime data are never
  migrated.
EOF
}

bw_workspace_require_tools() {
  bw_have jq || bw_die "jq is required for workspace profiles. Re-run the base package phase."
  bw_have git || bw_die "git is required for workspace profiles."
  bw_have sha256sum || bw_die "sha256sum is required for workspace profiles."
}

bw_workspace_require_platform() {
  local requested="${1:-}"
  case "$BW_PLATFORM" in
  termux)
    bw_die "Workspace profiles are available only on Arch Linux under Windows WSL 2, not Termux on Android. The Bloody Writer base remains fully supported in Termux."
    ;;
  wsl) ;;
  *) bw_die "Workspace profiles require Arch Linux under Windows WSL 2." ;;
  esac

  # This test hook exercises the real dispatch guard without requiring privileged CI. It is
  # honored only in BW_TEST_MODE and always stops through the same production guidance path.
  if { ((EUID == 0)) && [[ $BW_TEST_MODE != 1 ]]; } ||
    [[ $BW_TEST_MODE == 1 && ${BW_WORKSPACE_TEST_ROOT:-0} == 1 ]]; then
    bw_workspace_root_guidance "$requested"
  fi

  if [[ $BW_TEST_MODE != 1 ]]; then
    bw_is_wsl || bw_die "Workspace profiles require Windows WSL 2."
    grep -qi 'wsl2' /proc/sys/kernel/osrelease 2>/dev/null || bw_die "Workspace profiles require WSL 2."
    bw_is_arch || bw_die "Workspace profiles require the official Arch Linux WSL distribution."
    ((EUID != 0)) || bw_die "Run workspace commands as a normal user, not root."
  fi
}

bw_workspace_root_guidance() {
  local requested="${1:-}" clone_command='gh repo clone OWNER/REPOSITORY ~/projects/REPOSITORY'
  local apply_command='bloody-writer workspace apply ~/projects/REPOSITORY/bloody-writer.workspace.json'
  if [[ -n $requested && -f $requested && ! -L $requested ]]; then
    local profile_dir project_root remote repository project_name
    profile_dir="$(cd -- "$(dirname -- "$requested")" && pwd -P)"
    project_root="$(git -C "$profile_dir" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n $project_root ]]; then
      remote="$(git -C "$project_root" config --get remote.origin.url 2>/dev/null || true)"
      repository="$(sed -nE 's#^(git@github\.com:|https://github\.com/)([^/]+/[^/]+)(\.git)?$#\2#p' <<<"$remote")"
      repository="${repository%.git}"
      project_name="$(basename -- "$project_root")"
      if [[ $repository =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
        clone_command="gh repo clone $repository ~/projects/$project_name"
        apply_command="bloody-writer workspace apply ~/projects/$project_name/bloody-writer.workspace.json"
      fi
    fi
  fi
  cat >&2 <<'EOF'
ERROR: A workspace profile cannot run as root.

Safe fresh-machine sequence:
  1. Clone public Bloody Writer and run ./install.sh in the fresh Arch WSL root shell.
  2. Complete the displayed WSL restart and resume as the new normal user.
  3. Complete GitHub and Codex authentication as that user.
  4. Clone the private project at the displayed authentication checkpoint:
EOF
  printf '       %s\n' "$clone_command" >&2
  printf '  5. Run %s\n\n' "$apply_command" >&2
  cat >&2 <<'EOF'

Bloody Writer will not copy a private project or credentials out of /root.
EOF
  exit 1
}

bw_workspace_check_keys() {
  local file="$1"
  jq -e '
    def exact($allowed): ((keys_unsorted - $allowed) | length) == 0;
    exact(["$schema","schema_version","profile","platform","packages","versions","requirements","system_files","environment_guard","lifecycle","ports","capabilities"]) and
    (.profile | exact(["id","display_name","minimum_bloody_writer_version","review_state"])) and
    (.platform | exact(["distribution","environment","wsl_version"])) and
    (.packages | exact(["pacman","npm_global"])) and
    (.versions | exact(["php","node","pnpm"])) and
    ([.versions[] | exact(["source","requirement"])] | all) and
    (.requirements | exact(["binaries","php_extensions"])) and
    ([.system_files[] | exact(["adapter","source","destination"])] | all) and
    (.environment_guard | exact(["app_env","app_url_scope","db_connection","sqlite_backup"])) and
    (.lifecycle | exact(["setup","verify","development"])) and
    ([.lifecycle.setup[], .lifecycle.verify[], .lifecycle.development | exact(["argv"])] | all) and
    ([.ports[] | exact(["host","port","purpose"])] | all) and
    (.capabilities | exact(["bloody_writer_base"]))
  ' "$file" >/dev/null || bw_die "Workspace profile contains missing or unknown keys."
}

bw_workspace_validate_lifecycle_commands() {
  local file="$1" command_json executable
  while IFS= read -r command_json; do
    jq -e '(.argv | type == "array" and length > 0) and all(.argv[]; type == "string" and length > 0 and (test("[\u0000-\u001F\u007F]") | not))' \
      <<<"$command_json" >/dev/null || bw_die "Lifecycle arguments cannot contain empty values or control characters."
    executable="$(jq -r '.argv[0]' <<<"$command_json")"
    [[ $executable =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] ||
      bw_die "Lifecycle executable must be a safe, unqualified command token: $executable"
    case "$executable" in
    sh | bash | zsh | dash | fish | ksh | env | sudo | doas | su | command)
      bw_die "Lifecycle executable is not allowed in schema version 1: $executable"
      ;;
    esac
  done < <(jq -c '.lifecycle.setup[], .lifecycle.verify[], .lifecycle.development' "$file")
}

bw_workspace_require_clean_command_source() {
  local root="$1" file="$2" executable="$3" source="$4"
  jq -e --arg executable "$executable" \
    '[.lifecycle.setup[].argv[0], .lifecycle.verify[].argv[0], .lifecycle.development.argv[0]] | index($executable) != null' \
    "$file" >/dev/null || return 0
  [[ -f $root/$source && ! -L $root/$source ]] || bw_die "$executable lifecycle commands require a regular $source."
  git -C "$root" ls-files --error-unmatch -- "$source" >/dev/null 2>&1 || bw_die "$executable lifecycle commands require tracked $source."
  git -C "$root" diff --quiet HEAD -- "$source" || bw_die "$source has uncommitted bytes; refusing lifecycle indirection."
  git -C "$root" diff --cached --quiet HEAD -- "$source" || bw_die "$source has staged but uncommitted bytes; refusing lifecycle indirection."
}

bw_workspace_sorted_unique() {
  local file="$1" expression="$2" label="$3"
  local values sorted
  values="$(jq -r "$expression | .[]" "$file")"
  sorted="$(printf '%s\n' "$values" | sed '/^$/d' | LC_ALL=C sort -u)"
  [[ $values == "$sorted" ]] || bw_die "$label must be sorted and contain no duplicates."
}

bw_workspace_validate_path_token() {
  local value="$1" label="$2"
  [[ -n $value && $value != /* && $value != *$'\n'* && $value != *$'\r'* ]] ||
    bw_die "$label must be a project-relative path."
  case "/$value/" in
  */../* | */./*) bw_die "$label contains path traversal: $value" ;;
  esac
}

bw_workspace_semver_at_least() {
  local current="$1" required="$2"
  [[ $current =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && $required =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  [[ $(printf '%s\n%s\n' "$required" "$current" | sort -V | tail -n1) == "$current" ]]
}

bw_workspace_validate_file() {
  local requested="$1" allow_candidate="${2:-0}"
  bw_workspace_require_platform "$requested"
  bw_workspace_require_tools
  [[ -n $requested ]] || bw_die "A workspace profile path is required."
  [[ ! -L $requested ]] || bw_die "Workspace profiles cannot be symlinks: $requested"
  [[ -f $requested ]] || bw_die "Workspace profile is not a regular file: $requested"
  local size
  size="$(wc -c <"$requested")"
  ((size <= BW_WORKSPACE_MAX_BYTES)) || bw_die "Workspace profile exceeds $BW_WORKSPACE_MAX_BYTES bytes."
  jq -e 'type == "object"' "$requested" >/dev/null 2>&1 || bw_die "Workspace profile is malformed JSON."
  bw_workspace_check_keys "$requested"

  jq -e '
    .schema_version == 1 and
    (."$schema" | type == "string" and length > 0) and
    (.profile.id | test("^[a-z0-9][a-z0-9-]{1,62}$")) and
    (.profile.display_name | type == "string" and length > 0 and length <= 120) and
    (.profile.minimum_bloody_writer_version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) and
    (.profile.review_state == "approved" or .profile.review_state == "candidate") and
    .platform == {"distribution":"arch","environment":"wsl","wsl_version":2} and
    (.packages.pacman | type == "array") and
    (.packages.npm_global | type == "array") and
    (.requirements.binaries | type == "array") and
    (.requirements.php_extensions | type == "array") and
    ([.versions.php,.versions.node,.versions.pnpm][] | (.source | type == "string" and length > 0) and (.requirement | type == "string" and length > 0)) and
    (.system_files | type == "array") and
    (.environment_guard == {"app_env":"local","app_url_scope":"loopback","db_connection":"sqlite","sqlite_backup":true}) and
    (.lifecycle.setup | type == "array") and
    (.lifecycle.verify | type == "array") and
    (.lifecycle.development.argv | type == "array" and length > 0 and all(.[]; type == "string" and length > 0)) and
    ([.lifecycle.setup[].argv[], .lifecycle.verify[].argv[]] | all(.[]; type == "string" and length > 0)) and
    (.ports | type == "array") and
    ([.ports[] | (.host == "127.0.0.1" or .host == "localhost" or .host == "::1") and (.port | type == "number" and . >= 1 and . <= 65535) and (.purpose | type == "string" and length > 0)] | all) and
    .capabilities == {"bloody_writer_base":true}
  ' "$requested" >/dev/null || bw_die "Workspace profile version 1 has invalid values or types."
  jq -e 'all(.system_files[]; .adapter == "php-conf")' "$requested" >/dev/null ||
    bw_die "Schema version 1 supports only the php-conf system-file adapter."
  bw_workspace_validate_lifecycle_commands "$requested"

  if [[ $(jq -r '.profile.review_state' "$requested") != approved && $allow_candidate != 1 ]]; then
    bw_die "Candidate workspace profiles cannot be validated or applied. Review every field, then set profile.review_state to approved."
  fi
  bw_workspace_sorted_unique "$requested" '.packages.pacman' "pacman packages"
  bw_workspace_sorted_unique "$requested" '.packages.npm_global' "npm global packages"
  bw_workspace_sorted_unique "$requested" '.requirements.binaries' "required binaries"
  bw_workspace_sorted_unique "$requested" '.requirements.php_extensions' "PHP extensions"

  local package
  while IFS= read -r package; do
    [[ $package =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] || bw_die "Unsafe pacman package name: $package"
  done < <(jq -r '.packages.pacman[]' "$requested")
  while IFS= read -r package; do
    [[ $package =~ ^(@[a-z0-9._-]+/)?[a-z0-9][a-z0-9._-]*$ ]] || bw_die "Unsafe npm package name: $package"
  done < <(jq -r '.packages.npm_global[]' "$requested")

  local profile_dir root relative commit
  profile_dir="$(cd -- "$(dirname -- "$requested")" && pwd -P)"
  root="$(git -C "$profile_dir" rev-parse --show-toplevel 2>/dev/null)" || bw_die "Workspace profile must be stored in a Git repository."
  root="$(readlink -f -- "$root")"
  requested="$(readlink -f -- "$requested")"
  case "$requested" in
  "$root"/*) ;;
  *) bw_die "Workspace profile resolves outside its Git repository." ;;
  esac
  relative="${requested#"$root"/}"
  git -C "$root" ls-files --error-unmatch -- "$relative" >/dev/null 2>&1 || bw_die "Workspace profile must be tracked by Git: $relative"
  git -C "$root" diff --quiet HEAD -- "$relative" || bw_die "Workspace profile has uncommitted bytes. Commit the reviewed profile before validation: $relative"
  git -C "$root" diff --cached --quiet HEAD -- "$relative" || bw_die "Workspace profile has staged but uncommitted bytes. Commit it before validation: $relative"
  commit="$(git -C "$root" rev-parse HEAD)"

  local source destination source_path source_relative
  while IFS=$'\t' read -r source destination; do
    bw_workspace_validate_path_token "$source" "system-file source"
    [[ $destination =~ ^/etc/php/conf\.d/[A-Za-z0-9._-]+\.ini$ ]] || bw_die "Unsupported system-file destination: $destination"
    source_path="$root/$source"
    [[ ! -L $source_path ]] || bw_die "System-file sources cannot be symlinks: $source"
    [[ -f $source_path ]] || bw_die "System-file source is not a regular file: $source"
    source_path="$(readlink -f -- "$source_path")"
    case "$source_path" in
    "$root"/*) ;;
    *) bw_die "System-file source escapes its repository: $source" ;;
    esac
    source_relative="${source_path#"$root"/}"
    git -C "$root" ls-files --error-unmatch -- "$source_relative" >/dev/null 2>&1 || bw_die "System-file source must be tracked by Git: $source"
    git -C "$root" diff --quiet HEAD -- "$source_relative" || bw_die "System-file source has uncommitted bytes: $source"
    git -C "$root" diff --cached --quiet HEAD -- "$source_relative" || bw_die "System-file source has staged but uncommitted bytes: $source"
  done < <(jq -r '.system_files[] | [.source,.destination] | @tsv' "$requested")

  local source_field
  while IFS= read -r source_field; do
    bw_workspace_validate_path_token "$source_field" "version source"
    [[ -f $root/$source_field && ! -L $root/$source_field ]] || bw_die "Version source must be a regular project file: $source_field"
    git -C "$root" ls-files --error-unmatch -- "$source_field" >/dev/null 2>&1 || bw_die "Version source must be tracked by Git: $source_field"
    git -C "$root" diff --quiet HEAD -- "$source_field" || bw_die "Version source has uncommitted bytes: $source_field"
    git -C "$root" diff --cached --quiet HEAD -- "$source_field" || bw_die "Version source has staged but uncommitted bytes: $source_field"
  done < <(jq -r '.versions | [.php.source,.node.source,.pnpm.source][]' "$requested")

  [[ $(jq -r '.versions.php.source' "$requested") == .php-version ]] || bw_die "Schema version 1 derives PHP from .php-version."
  [[ $(jq -r '.versions.node.source' "$requested") == .node-version ]] || bw_die "Schema version 1 derives Node.js from .node-version."
  [[ $(jq -r '.versions.pnpm.source' "$requested") == package.json ]] || bw_die "Schema version 1 derives pnpm from package.json."
  local derived
  derived="$(tr -d '[:space:]' <"$root/.php-version")"
  [[ $derived == "$(jq -r '.versions.php.requirement' "$requested")" ]] || bw_die "PHP requirement does not match .php-version."
  derived="$(tr -d '[:space:]' <"$root/.node-version")"
  [[ $derived == "$(jq -r '.versions.node.requirement' "$requested")" ]] || bw_die "Node.js requirement does not match .node-version."
  derived="$(jq -r '.packageManager // "" | sub("^pnpm@";"")' "$root/package.json")"
  [[ $derived == "$(jq -r '.versions.pnpm.requirement' "$requested")" ]] || bw_die "pnpm requirement does not match package.json packageManager."
  bw_workspace_require_clean_command_source "$root" "$requested" composer composer.json
  bw_workspace_require_clean_command_source "$root" "$requested" pnpm package.json
  bw_workspace_require_clean_command_source "$root" "$requested" npm package.json

  local minimum
  minimum="$(jq -r '.profile.minimum_bloody_writer_version' "$requested")"
  bw_workspace_semver_at_least "$BLOODY_WRITER_VERSION" "$minimum" ||
    bw_die "This profile requires Bloody Writer $minimum or newer; current version is $BLOODY_WRITER_VERSION."

  BW_WORKSPACE_FILE="$requested"
  BW_WORKSPACE_ROOT="$root"
  BW_WORKSPACE_ID="$(jq -r '.profile.id' "$requested")"
  BW_WORKSPACE_DIGEST="$(sha256sum "$requested" | awk '{print $1}')"
  BW_WORKSPACE_GENERATION="$BW_STATE_DIR/workspaces/$BW_WORKSPACE_ID/$BW_WORKSPACE_DIGEST"
  BW_WORKSPACE_GIT_COMMIT="$commit"
  export BW_WORKSPACE_FILE BW_WORKSPACE_ROOT BW_WORKSPACE_ID BW_WORKSPACE_DIGEST BW_WORKSPACE_GENERATION BW_WORKSPACE_GIT_COMMIT
}

bw_workspace_validate_command() {
  (($# == 1)) || bw_die "workspace validate requires exactly one FILE."
  bw_workspace_validate_file "$1"
  bw_log "Workspace profile is valid and approved."
  bw_note "Profile: $(jq -r '.profile.display_name' "$BW_WORKSPACE_FILE") ($BW_WORKSPACE_ID)"
  bw_note "Project root: $BW_WORKSPACE_ROOT"
  bw_note "Git commit: $BW_WORKSPACE_GIT_COMMIT"
  bw_note "Manifest SHA-256: $BW_WORKSPACE_DIGEST"
}

bw_workspace_effective_destination() {
  local destination="$1"
  if [[ -n ${BW_WORKSPACE_ETC_ROOT:-} ]]; then
    printf '%s%s\n' "${BW_WORKSPACE_ETC_ROOT%/}" "$destination"
  else
    printf '%s\n' "$destination"
  fi
}

bw_workspace_base_complete() {
  local phase
  for phase in "${BW_PHASES[@]}"; do
    bw_phase_done "$phase" || return 1
  done
}

bw_workspace_phase_marker() {
  printf '%s/completed/%s\n' "$BW_WORKSPACE_GENERATION" "$1"
}

bw_workspace_phase_done() {
  [[ -f $(bw_workspace_phase_marker "$1") ]]
}

bw_workspace_mark_phase() {
  local marker
  marker="$(bw_workspace_phase_marker "$1")"
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Would mark workspace phase $1 complete."
    return 0
  fi
  mkdir -p "$(dirname -- "$marker")"
  {
    printf 'version=%s\n' "$BLOODY_WRITER_VERSION"
    printf 'manifest_sha256=%s\n' "$BW_WORKSPACE_DIGEST"
    printf 'project_commit=%s\n' "$BW_WORKSPACE_GIT_COMMIT"
  } >"$marker"
}

bw_workspace_write_active() {
  [[ $BW_DRY_RUN == 1 ]] && return 0
  local active="$BW_STATE_DIR/workspaces/active.json" temporary
  mkdir -p "$(dirname -- "$active")"
  temporary="$(mktemp "$BW_STATE_DIR/workspaces/.active.XXXXXX")"
  jq -n --arg file "$BW_WORKSPACE_FILE" --arg digest "$BW_WORKSPACE_DIGEST" --arg id "$BW_WORKSPACE_ID" \
    '{profile_id:$id,manifest:$file,manifest_sha256:$digest}' >"$temporary"
  chmod 600 "$temporary"
  mv -- "$temporary" "$active"
}

bw_workspace_read_env_value() {
  local file="$1" key="$2"
  awk -v wanted="$key" '
    /^[[:space:]]*#/ { next }
    index($0, "=") == 0 { next }
    {
      name=substr($0,1,index($0,"=")-1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
      if (name != wanted) next
      value=substr($0,index($0,"=")+1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if ((substr(value,1,1) == "\"" && substr(value,length(value),1) == "\"") ||
          (substr(value,1,1) == "\047" && substr(value,length(value),1) == "\047")) {
        value=substr(value,2,length(value)-2)
      }
      print value
      exit
    }
  ' "$file"
}

bw_workspace_guard_local_environment() {
  local env_file="$BW_WORKSPACE_ROOT/.env"
  [[ -e $env_file ]] || {
    bw_note ".env is absent; the approved project setup may create a local file."
    return 0
  }
  [[ -f $env_file && ! -L $env_file ]] || bw_die ".env must be a regular local file when present."
  local app_env app_url db_connection
  app_env="$(bw_workspace_read_env_value "$env_file" APP_ENV)"
  app_url="$(bw_workspace_read_env_value "$env_file" APP_URL)"
  db_connection="$(bw_workspace_read_env_value "$env_file" DB_CONNECTION)"
  [[ $app_env == local ]] || bw_die "Project setup is blocked: .env must contain APP_ENV=local."
  [[ $db_connection == sqlite ]] || bw_die "Project setup is blocked: .env must contain DB_CONNECTION=sqlite."
  [[ $app_url =~ ^https?://(127\.0\.0\.1|localhost|\[::1\])(:[0-9]+)?(/.*)?$ ]] ||
    bw_die "Project setup is blocked: APP_URL must use a loopback host."
}

bw_workspace_sqlite_path() {
  printf '%s/database/database.sqlite\n' "$BW_WORKSPACE_ROOT"
}

bw_workspace_backup_sqlite() {
  [[ $(jq -r '.environment_guard.sqlite_backup' "$BW_WORKSPACE_FILE") == true ]] || return 0
  local database backup
  database="$(bw_workspace_sqlite_path)"
  [[ -f $database && ! -L $database ]] || return 0
  backup="$BW_WORKSPACE_GENERATION/backups/sqlite/$(basename -- "$database").before-setup"
  if [[ -f $backup ]]; then
    if cmp -s -- "$database" "$backup"; then
      bw_note "An identical SQLite backup already exists for this profile generation: $backup"
      return 0
    fi
    backup="$backup.$(sha256sum "$database" | awk '{print $1}')"
    if [[ -f $backup ]]; then
      bw_note "This SQLite generation is already preserved: $backup"
      return 0
    fi
  fi
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_note "Would back up SQLite database before project setup: $database"
    return 0
  fi
  mkdir -p "$(dirname -- "$backup")"
  cp -p -- "$database" "$backup"
  chmod 600 "$backup"
  bw_note "SQLite database backup: $backup"
}

bw_workspace_run_argv() {
  local json="$1"
  local argv=()
  mapfile -d '' -t argv < <(jq -j '.argv[] | ., "\u0000"' <<<"$json")
  ((${#argv[@]})) || bw_die "Lifecycle command has no arguments."
  bw_note "Running in $BW_WORKSPACE_ROOT:$(bw_quote_command "${argv[@]}")"
  if [[ $BW_DRY_RUN == 1 ]]; then
    return 0
  fi
  (cd "$BW_WORKSPACE_ROOT" && TMPDIR=/tmp "${argv[@]}")
}

bw_workspace_phase_packages() {
  local missing=() package
  while IFS= read -r package; do
    if [[ -n ${BW_WORKSPACE_INSTALLED_PACKAGES_FILE:-} ]]; then
      grep -Fxq -- "$package" "$BW_WORKSPACE_INSTALLED_PACKAGES_FILE" || missing+=("$package")
    elif ! pacman -Qq -- "$package" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done < <(jq -r '.packages.pacman[]' "$BW_WORKSPACE_FILE")
  if ((${#missing[@]})); then
    bw_log "Installing ${#missing[@]} missing Arch workspace package(s)."
    bw_run sudo pacman -S --needed "${missing[@]}"
  else
    bw_note "All Arch workspace packages are already installed."
  fi

  local npm_missing=()
  while IFS= read -r package; do
    if [[ -n ${BW_WORKSPACE_INSTALLED_NPM_FILE:-} ]]; then
      grep -Fxq -- "$package" "$BW_WORKSPACE_INSTALLED_NPM_FILE" || npm_missing+=("$package")
    elif ! npm list --global --depth=0 --json 2>/dev/null | jq -e --arg package "$package" '.dependencies[$package]' >/dev/null; then
      npm_missing+=("$package")
    fi
  done < <(jq -r '.packages.npm_global[]' "$BW_WORKSPACE_FILE")
  if ((${#npm_missing[@]})); then
    bw_log "Installing ${#npm_missing[@]} missing global npm workspace package(s)."
    bw_run sudo npm install --global "${npm_missing[@]}"
  fi
}

bw_workspace_phase_system_files() {
  local source destination effective backup
  while IFS=$'\t' read -r source destination; do
    effective="$(bw_workspace_effective_destination "$destination")"
    source="$BW_WORKSPACE_ROOT/$source"
    if [[ -f $effective ]] && cmp -s -- "$source" "$effective"; then
      bw_note "System file already matches: $destination"
      continue
    fi
    if [[ -e $effective || -L $effective ]]; then
      [[ -f $effective && ! -L $effective ]] || bw_die "Refusing to replace a non-regular system destination: $destination"
      backup="$BW_WORKSPACE_GENERATION/backups/system-files${destination}"
      if [[ -f $backup ]]; then
        backup="$backup.$(sha256sum "$effective" | awk '{print $1}')"
      fi
      bw_log "Backing up differing system file: $destination"
      if [[ $BW_DRY_RUN != 1 ]]; then
        mkdir -p "$(dirname -- "$backup")"
        cp -p -- "$effective" "$backup"
        chmod 600 "$backup"
      fi
    fi
    bw_log "Installing reviewed PHP configuration: $destination"
    if [[ -n ${BW_WORKSPACE_ETC_ROOT:-} ]]; then
      bw_run mkdir -p "$(dirname -- "$effective")"
      bw_run install -m 0644 -- "$source" "$effective"
    else
      bw_run sudo install -D -m 0644 -- "$source" "$destination"
    fi
    if [[ $BW_DRY_RUN != 1 ]]; then
      cmp -s -- "$source" "$effective" || bw_die "Installed system file did not verify: $destination"
    fi
  done < <(jq -r '.system_files[] | [.source,.destination] | @tsv' "$BW_WORKSPACE_FILE")
}

bw_workspace_phase_project_setup() {
  bw_workspace_guard_local_environment
  bw_workspace_backup_sqlite
  local command
  while IFS= read -r command; do
    bw_workspace_run_argv "$command"
  done < <(jq -c '.lifecycle.setup[]' "$BW_WORKSPACE_FILE")
}

bw_workspace_phase_verify() {
  local binary extension command
  while IFS= read -r binary; do
    if [[ $BW_DRY_RUN == 1 ]]; then
      bw_note "Would require command: $binary"
    else
      bw_have "$binary" || bw_die "Required workspace command is missing: $binary"
    fi
  done < <(jq -r '.requirements.binaries[]' "$BW_WORKSPACE_FILE")
  if jq -e '.requirements.php_extensions | length > 0' "$BW_WORKSPACE_FILE" >/dev/null; then
    if [[ $BW_DRY_RUN == 1 ]]; then
      bw_note "Would verify required PHP extensions."
    else
      local loaded
      loaded="$(php -m | tr '[:upper:]' '[:lower:]')"
      while IFS= read -r extension; do
        grep -Fxiq -- "$extension" <<<"$loaded" || bw_die "Required PHP extension is missing: $extension"
      done < <(jq -r '.requirements.php_extensions[]' "$BW_WORKSPACE_FILE")
    fi
  fi
  bw_workspace_verify_versions
  while IFS= read -r command; do
    bw_workspace_run_argv "$command"
  done < <(jq -c '.lifecycle.verify[]' "$BW_WORKSPACE_FILE")
}

bw_workspace_observed_version() {
  case "$1" in
  php) bw_have php && php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null ;;
  node) bw_have node && node --version 2>/dev/null | sed 's/^v//' ;;
  pnpm) bw_have pnpm && pnpm --version 2>/dev/null ;;
  esac
}

bw_workspace_version_matches() {
  local name="$1" actual="$2" required="$3"
  case "$name" in
  php) [[ $actual == "$required" ]] ;;
  node | pnpm) [[ $actual == "$required" ]] ;;
  esac
}

bw_workspace_verify_versions() {
  local name actual required
  for name in php node pnpm; do
    required="$(jq -r --arg name "$name" '.versions[$name].requirement' "$BW_WORKSPACE_FILE")"
    if [[ $BW_DRY_RUN == 1 ]]; then
      bw_note "Would require $name version: $required"
      continue
    fi
    actual="$(bw_workspace_observed_version "$name")"
    [[ -n $actual ]] || bw_die "Required runtime is missing: $name"
    bw_workspace_version_matches "$name" "$actual" "$required" || bw_die "Required $name version is $required; found $actual."
  done
}

bw_workspace_apply_loaded() {
  if [[ $BW_DRY_RUN != 1 ]]; then
    bw_workspace_base_complete || bw_die "The Bloody Writer base installation is incomplete. Finish './install.sh' before applying a workspace profile."
  elif ! bw_workspace_base_complete; then
    bw_note "Dry run: base phase state is incomplete; previewing the workspace that would follow a completed base install."
  fi
  bw_note "Approved profile: $(jq -r '.profile.display_name' "$BW_WORKSPACE_FILE")"
  bw_note "Project root: $BW_WORKSPACE_ROOT"
  bw_note "Project commit: $BW_WORKSPACE_GIT_COMMIT"
  bw_note "Manifest SHA-256: $BW_WORKSPACE_DIGEST"
  if [[ $BW_DRY_RUN != 1 ]]; then
    bw_confirm "Trust and apply this exact profile generation?" || bw_die "Workspace profile was not trusted."
  fi
  bw_workspace_write_active

  local phase function
  for phase in "${BW_WORKSPACE_PHASES[@]}"; do
    if [[ $BW_FORCE != 1 ]] && bw_workspace_phase_done "$phase"; then
      bw_note "Skipping completed workspace phase: $phase"
      continue
    fi
    function="bw_workspace_phase_${phase#workspace-}"
    function="${function//-/_}"
    bw_log "Workspace phase $phase"
    "$function"
    bw_workspace_mark_phase "$phase"
  done
  if [[ $BW_DRY_RUN == 1 ]]; then
    bw_log "Workspace preview complete; no state was changed."
  else
    bw_log "Bloody Writer base and workspace profile are complete."
    printf '\nDaily development entrypoint:\n\n  cd %q\n' "$BW_WORKSPACE_ROOT"
    local development=()
    mapfile -d '' -t development < <(jq -j '.lifecycle.development.argv[] | ., "\u0000"' "$BW_WORKSPACE_FILE")
    printf ' '
    bw_quote_command "${development[@]}"
  fi
}

bw_workspace_apply_command() {
  local file=""
  BW_DRY_RUN=0
  BW_FORCE=0
  while (($#)); do
    case "$1" in
    --yes) BW_ASSUME_YES=1 ;;
    --dry-run) BW_DRY_RUN=1 ;;
    --force) BW_FORCE=1 ;;
    -h | --help) bw_workspace_usage; return 0 ;;
    -*) bw_die "Unknown workspace apply option: $1" ;;
    *) [[ -z $file ]] || bw_die "workspace apply accepts one FILE."; file="$1" ;;
    esac
    shift
  done
  [[ -n $file ]] || bw_die "workspace apply requires FILE."
  export BW_DRY_RUN BW_FORCE BW_ASSUME_YES
  bw_workspace_validate_file "$file"
  bw_workspace_apply_loaded
}

bw_workspace_status_command() {
  bw_workspace_require_platform
  bw_workspace_require_tools
  local active="$BW_STATE_DIR/workspaces/active.json"
  if [[ ! -f $active ]]; then
    printf 'Active workspace: none\n'
    return 0
  fi
  jq -e 'type == "object" and (.profile_id|type=="string") and (.manifest|type=="string") and (.manifest_sha256|type=="string")' "$active" >/dev/null ||
    bw_die "Active workspace state is invalid: $active"
  local file recorded current phase state
  file="$(jq -r '.manifest' "$active")"
  recorded="$(jq -r '.manifest_sha256' "$active")"
  printf 'Active workspace: %s\n' "$(jq -r '.profile_id' "$active")"
  printf 'Manifest: %s\n' "$file"
  printf 'Recorded SHA-256: %s\n' "$recorded"
  if [[ -f $file && ! -L $file ]]; then
    current="$(sha256sum "$file" | awk '{print $1}')"
    printf 'Current SHA-256: %s%s\n' "$current" "$([[ $current == "$recorded" ]] && printf ' (unchanged)' || printf ' (changed; new validation and trust required)')"
  else
    printf 'Current manifest: missing or unsafe\n'
  fi
  BW_WORKSPACE_GENERATION="$BW_STATE_DIR/workspaces/$(jq -r '.profile_id' "$active")/$recorded"
  for phase in "${BW_WORKSPACE_PHASES[@]}"; do
    state=pending
    bw_workspace_phase_done "$phase" && state=complete
    printf '%-28s %s\n' "$phase" "$state"
  done
}

bw_workspace_report_active_audit() {
  local active="$BW_STATE_DIR/workspaces/active.json"
  [[ -f $active ]] || return 0
  local file audit_output
  file="$(jq -r '.manifest // empty' "$active" 2>/dev/null || true)"
  if [[ -z $file ]]; then
    bw_warn "Active workspace state is unreadable; run 'bloody-writer workspace status'."
    return 0
  fi
  if audit_output="$(
    {
      bw_workspace_validate_file "$file"
      bw_workspace_audit_loaded
    } 2>&1
  )"; then
    bw_note "Active workspace audit: satisfied ($(jq -r '.profile_id' "$active"))."
  else
    bw_warn "Active workspace audit: attention required. Run 'bloody-writer workspace audit $file'."
    bw_note "$(tail -n 1 <<<"$audit_output")"
  fi
}

bw_workspace_resume_command() {
  bw_workspace_require_platform
  bw_workspace_require_tools
  local active="$BW_STATE_DIR/workspaces/active.json"
  [[ -f $active ]] || bw_die "No active workspace profile is recorded."
  local file
  file="$(jq -r '.manifest // empty' "$active" 2>/dev/null)"
  [[ -n $file ]] || bw_die "Active workspace state is invalid."
  bw_workspace_apply_command "$file" "$@"
}

bw_workspace_audit_loaded() {
  local failures=0 package binary extension source destination effective requirement actual
  printf 'Workspace audit: %s\n' "$(jq -r '.profile.display_name' "$BW_WORKSPACE_FILE")"
  while IFS= read -r package; do
    if pacman -Qq -- "$package" >/dev/null 2>&1; then
      printf '  [ok] pacman package %s\n' "$package"
    else
      printf '  [missing] pacman package %s\n' "$package"
      failures=$((failures + 1))
    fi
  done < <(jq -r '.packages.pacman[]' "$BW_WORKSPACE_FILE")
  local npm_json='{}'
  if jq -e '.packages.npm_global | length > 0' "$BW_WORKSPACE_FILE" >/dev/null; then
    if bw_have npm; then
      npm_json="$(npm list --global --depth=0 --json 2>/dev/null || printf '{}')"
      jq -e 'type == "object"' <<<"$npm_json" >/dev/null 2>&1 || npm_json='{}'
    fi
    while IFS= read -r package; do
      if jq -e --arg package "$package" '.dependencies[$package] != null' <<<"$npm_json" >/dev/null; then
        printf '  [ok] global npm package %s\n' "$package"
      else
        printf '  [missing] global npm package %s\n' "$package"
        failures=$((failures + 1))
      fi
    done < <(jq -r '.packages.npm_global[]' "$BW_WORKSPACE_FILE")
  fi
  while IFS= read -r binary; do
    if bw_have "$binary"; then
      printf '  [ok] command %s\n' "$binary"
    else
      printf '  [missing] command %s\n' "$binary"
      failures=$((failures + 1))
    fi
  done < <(jq -r '.requirements.binaries[]' "$BW_WORKSPACE_FILE")
  if bw_have php; then
    local loaded
    loaded="$(php -m | tr '[:upper:]' '[:lower:]')"
    while IFS= read -r extension; do
      if grep -Fxiq -- "$extension" <<<"$loaded"; then
        printf '  [ok] PHP extension %s\n' "$extension"
      else
        printf '  [missing] PHP extension %s\n' "$extension"
        failures=$((failures + 1))
      fi
    done < <(jq -r '.requirements.php_extensions[]' "$BW_WORKSPACE_FILE")
  fi
  while IFS=$'\t' read -r source destination; do
    effective="$(bw_workspace_effective_destination "$destination")"
    if [[ -f $effective ]] && cmp -s -- "$BW_WORKSPACE_ROOT/$source" "$effective"; then
      printf '  [ok] system file %s\n' "$destination"
    else
      printf '  [different] system file %s\n' "$destination"
      failures=$((failures + 1))
    fi
  done < <(jq -r '.system_files[] | [.source,.destination] | @tsv' "$BW_WORKSPACE_FILE")
  for requirement in php node pnpm; do
    actual="$(bw_workspace_observed_version "$requirement")"
    local required
    required="$(jq -r --arg name "$requirement" '.versions[$name].requirement' "$BW_WORKSPACE_FILE")"
    if [[ -n $actual ]] && bw_workspace_version_matches "$requirement" "$actual" "$required"; then
      printf '  [ok] %s version %s (profile %s)\n' "$requirement" "$actual" "$required"
    else
      printf '  [mismatch] %s version %s (profile %s)\n' "$requirement" "${actual:-none}" "$required"
      failures=$((failures + 1))
    fi
  done
  if bw_workspace_base_complete; then
    printf '  [ok] Bloody Writer base phase state complete\n'
  else
    printf '  [notice] Bloody Writer base phase state is not complete on this workstation\n'
  fi
  ((failures == 0))
}

bw_workspace_audit_command() {
  (($# == 1)) || bw_die "workspace audit requires exactly one FILE."
  bw_workspace_validate_file "$1"
  bw_workspace_audit_loaded
}

bw_workspace_json_string_array() {
  if (($# == 0)); then
    printf '[]\n'
  else
    printf '%s\n' "$@" | jq -Rsc 'split("\n")[:-1] | sort | unique'
  fi
}

bw_workspace_scan_command() {
  bw_workspace_require_platform
  bw_workspace_require_tools
  bw_have rg || bw_die "ripgrep (rg) is required for the curated workspace scanner. Finish the Bloody Writer base package phase."
  local project="" output=""
  while (($#)); do
    case "$1" in
    --project) shift; (($#)) || bw_die "--project requires DIR."; project="$1" ;;
    --output) shift; (($#)) || bw_die "--output requires FILE."; output="$1" ;;
    -h | --help) bw_workspace_usage; return 0 ;;
    *) bw_die "Unknown workspace scan option: $1" ;;
    esac
    shift
  done
  [[ -n $project && -n $output ]] || bw_die "workspace scan requires --project DIR --output FILE."
  [[ -d $project && ! -L $project ]] || bw_die "Scan project must be a regular directory."
  project="$(readlink -f -- "$project")"
  local root
  root="$(git -C "$project" rev-parse --show-toplevel 2>/dev/null)" || bw_die "Scan project must be a Git repository."
  [[ $root == "$project" ]] || bw_die "--project must name the Git repository root."
  [[ ! -e $output && ! -L $output ]] || bw_die "Refusing to overwrite an existing scan output. Choose a new --output path."

  local metadata
  for metadata in .php-version .node-version package.json; do
    [[ -f $project/$metadata && ! -L $project/$metadata ]] || bw_die "Scanner requires a regular tracked $metadata."
    git -C "$project" ls-files --error-unmatch -- "$metadata" >/dev/null 2>&1 || bw_die "Scanner requires tracked metadata: $metadata"
  done
  if [[ -e $project/composer.json ]]; then
    [[ -f $project/composer.json && ! -L $project/composer.json ]] || bw_die "Scanner requires composer.json to be a regular file."
    git -C "$project" ls-files --error-unmatch -- composer.json >/dev/null 2>&1 || bw_die "Scanner will not read an untracked composer.json."
  fi

  local php_version node_version pnpm_version
  php_version="$(tr -d '[:space:]' <"$project/.php-version" 2>/dev/null || true)"
  node_version="$(tr -d '[:space:]' <"$project/.node-version" 2>/dev/null || true)"
  pnpm_version="$(jq -r '.packageManager // "" | sub("^pnpm@";"")' "$project/package.json" 2>/dev/null || true)"
  [[ -n $php_version && -n $node_version && -n $pnpm_version ]] || bw_die "Scanner requires .php-version, .node-version, and package.json packageManager metadata."

  local relevant=(base-devel composer git github-cli jq keychain nginx nodejs-lts-krypton npm php php-fpm php-gd php-sqlite pnpm python ripgrep tree)
  local packages=() package
  local explicit_packages_source="${BW_WORKSPACE_SCAN_EXPLICIT_PACKAGES_FILE:-}"
  local explicit_packages=()
  if [[ -n $explicit_packages_source ]]; then
    # Deterministic fixture hook: this file contains only `pacman -Qqe`-style package names.
    # Install-reason metadata is never serialized into the generated profile.
    mapfile -t explicit_packages < <(sed '/^$/d' "$explicit_packages_source" | LC_ALL=C sort -u)
  else
    local explicit_output
    explicit_output="$(pacman -Qqe)" || bw_die "Unable to query explicit Arch packages with pacman -Qqe."
    mapfile -t explicit_packages < <(printf '%s\n' "$explicit_output" | sed '/^$/d' | LC_ALL=C sort -u)
  fi
  for package in "${relevant[@]}"; do
    printf '%s\n' "${explicit_packages[@]}" | grep -Fxq -- "$package" && packages+=("$package")
  done
  local command owner
  local binaries=()
  for command in composer git gh jq nginx node npm php php-fpm pnpm python rg tree; do
    bw_have "$command" || continue
    binaries+=("$command")
    owner="$(pacman -Qqo -- "$(command -v "$command")" 2>/dev/null | head -n1 || true)"
    [[ $owner =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] || continue
    packages+=("$owner")
  done
  local npm_packages=()
  if [[ -n ${BW_WORKSPACE_SCAN_NPM_FILE:-} ]]; then
    while IFS= read -r package; do
      grep -Fxq -- "$package" "$BW_REPO_ROOT/manifests/npm-globals.txt" && continue
      if [[ -n ${BW_WORKSPACE_SCAN_PACMAN_OWNED_NPM_FILE:-} ]] &&
        grep -Fxq -- "$package" "$BW_WORKSPACE_SCAN_PACMAN_OWNED_NPM_FILE"; then
        continue
      fi
      npm_packages+=("$package")
    done < <(sed '/^$/d' "$BW_WORKSPACE_SCAN_NPM_FILE" | LC_ALL=C sort -u)
  elif bw_have npm; then
    local npm_root
    npm_root="$(npm root --global 2>/dev/null || true)"
    while IFS= read -r package; do
      grep -Fxq -- "$package" "$BW_REPO_ROOT/manifests/npm-globals.txt" && continue
      if [[ -n $npm_root ]] && pacman -Qqo -- "$npm_root/$package" >/dev/null 2>&1; then
        continue
      fi
      npm_packages+=("$package")
    done < <(npm list --global --depth=0 --json 2>/dev/null | jq -r '.dependencies // {} | keys[]' | LC_ALL=C sort)
  fi

  local system_files='[]'
  if [[ -f $project/tools/local-server/php-extensions.ini && ! -L $project/tools/local-server/php-extensions.ini ]] &&
    git -C "$project" ls-files --error-unmatch -- tools/local-server/php-extensions.ini >/dev/null 2>&1; then
    local effective
    effective="$(bw_workspace_effective_destination /etc/php/conf.d/20-ce-systems.ini)"
    if [[ -f $effective ]] && cmp -s -- "$project/tools/local-server/php-extensions.ini" "$effective"; then
      system_files='[{"adapter":"php-conf","source":"tools/local-server/php-extensions.ini","destination":"/etc/php/conf.d/20-ce-systems.ini"}]'
    fi
  fi

  local php_extensions=()
  if [[ -f $project/tools/local-server/php-extensions.ini && ! -L $project/tools/local-server/php-extensions.ini ]] &&
    git -C "$project" ls-files --error-unmatch -- tools/local-server/php-extensions.ini >/dev/null 2>&1; then
    mapfile -t php_extensions < <(sed -nE 's/^[[:space:]]*extension[[:space:]]*=[[:space:]]*([A-Za-z0-9_]+).*/\1/p' "$project/tools/local-server/php-extensions.ini" | LC_ALL=C sort -u)
  fi
  local setup_json='[]' verify_json='[]' development_json=''
  if [[ -f $project/composer.json ]] && jq -e '.scripts.setup' "$project/composer.json" >/dev/null; then
    setup_json='[{"argv":["composer","run","setup"]}]'
  fi
  local verification_entries=()
  if [[ -f $project/composer.json ]]; then
    jq -e '.scripts["server:check"]' "$project/composer.json" >/dev/null && verification_entries+=(composer-server)
    jq -e '.scripts.check' "$project/composer.json" >/dev/null && verification_entries+=(composer-check)
  fi
  if [[ -f $project/package.json ]] && jq -e '.scripts.check' "$project/package.json" >/dev/null; then
    verification_entries+=(pnpm-check)
  fi
  if [[ -f $project/composer.json ]] && jq -e '.scripts.dev' "$project/composer.json" >/dev/null; then
    development_json='{"argv":["composer","run","dev"]}'
  elif jq -e '.scripts.dev' "$project/package.json" >/dev/null; then
    development_json='{"argv":["pnpm","run","dev"]}'
  else
    bw_die "Scanner requires a standard Composer or pnpm development script."
  fi
  if ((${#verification_entries[@]})); then
    verify_json="$(printf '%s\n' "${verification_entries[@]}" | jq -Rsc 'split("\n")[:-1] | map(if .=="composer-server" then {argv:["composer","run","server:check"]} elif .=="composer-check" then {argv:["composer","check"]} else {argv:["pnpm","run","check"]} end)')"
  fi

  local ports_json='[]'
  if [[ -f $project/tools/local-server/nginx.conf && ! -L $project/tools/local-server/nginx.conf ]] &&
    git -C "$project" ls-files --error-unmatch -- tools/local-server/nginx.conf >/dev/null 2>&1; then
    if rg -q 'listen[[:space:]]+127\.0\.0\.1:8080' "$project/tools/local-server/nginx.conf"; then
      ports_json="$(jq -c '. + [{host:"127.0.0.1",port:8080,purpose:"Nginx application"}]' <<<"$ports_json")"
    fi
    if rg -q 'fastcgi_pass[[:space:]]+127\.0\.0\.1:9074' "$project/tools/local-server/nginx.conf"; then
      ports_json="$(jq -c '. + [{host:"127.0.0.1",port:9074,purpose:"PHP-FPM FastCGI"}]' <<<"$ports_json")"
    fi
  fi
  if [[ -f $project/vite.config.js && ! -L $project/vite.config.js ]] &&
    git -C "$project" ls-files --error-unmatch -- vite.config.js >/dev/null 2>&1 &&
    rg -q "host:[[:space:]]*['\"]127\.0\.0\.1['\"]" "$project/vite.config.js" &&
    rg -q 'port:[[:space:]]*5173' "$project/vite.config.js"; then
    ports_json="$(jq -c '. + [{host:"127.0.0.1",port:5173,purpose:"Vite development assets"}] | sort_by(.port)' <<<"$ports_json")"
  fi

  local output_dir temporary
  output_dir="$(dirname -- "$output")"
  mkdir -p "$output_dir"
  temporary="$(mktemp "$output_dir/.bloody-writer-workspace.XXXXXX")"
  local generated_id
  generated_id="$(basename -- "$project" | tr '[:upper:]_' '[:lower:]-' | tr -cd 'a-z0-9-')"
  [[ $generated_id =~ ^[a-z0-9][a-z0-9-]{1,62}$ ]] || generated_id=workspace-project
  jq -n \
    --arg schema "https://raw.githubusercontent.com/1w3j/bloody-writer/main/schemas/workspace-profile-v1.schema.json" \
    --arg id "$generated_id" \
    --arg display "$(basename -- "$project") development workspace" \
    --arg php "$php_version" --arg node "$node_version" --arg pnpm "$pnpm_version" \
    --argjson pacman "$(bw_workspace_json_string_array "${packages[@]}")" \
    --argjson npm "$(bw_workspace_json_string_array "${npm_packages[@]}")" \
    --argjson binaries "$(bw_workspace_json_string_array "${binaries[@]}")" \
    --argjson extensions "$(bw_workspace_json_string_array "${php_extensions[@]}")" \
    --argjson system_files "$system_files" --argjson setup "$setup_json" --argjson verify "$verify_json" --argjson development "$development_json" --argjson ports "$ports_json" \
    '{
      "$schema":$schema,
      schema_version:1,
      profile:{id:$id,display_name:$display,minimum_bloody_writer_version:"0.3.0",review_state:"candidate"},
      platform:{distribution:"arch",environment:"wsl",wsl_version:2},
      packages:{pacman:$pacman,npm_global:$npm},
      versions:{php:{source:".php-version",requirement:$php},node:{source:".node-version",requirement:$node},pnpm:{source:"package.json",requirement:$pnpm}},
      requirements:{binaries:$binaries,php_extensions:$extensions},
      system_files:$system_files,
      environment_guard:{app_env:"local",app_url_scope:"loopback",db_connection:"sqlite",sqlite_backup:true},
      lifecycle:{setup:$setup,verify:$verify,development:$development},
      ports:$ports,
      capabilities:{bloody_writer_base:true}
    }' >"$temporary"
  mv -- "$temporary" "$output"
  bw_log "Candidate workspace profile written: $output"
  bw_warn "Candidate profiles cannot be applied. Review every field and exclusion, commit it, then change review_state to approved."
}

bw_workspace_command() {
  local subcommand="${1:-help}"
  shift || true
  case "$subcommand" in
  scan) bw_workspace_scan_command "$@" ;;
  validate) bw_workspace_validate_command "$@" ;;
  audit) bw_workspace_audit_command "$@" ;;
  apply) bw_workspace_apply_command "$@" ;;
  status) (($# == 0)) || bw_die "workspace status accepts no arguments."; bw_workspace_status_command ;;
  resume) bw_workspace_resume_command "$@" ;;
  help | -h | --help) bw_workspace_usage ;;
  *) bw_die "Unknown workspace command: $subcommand" ;;
  esac
}
