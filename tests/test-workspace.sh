#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

project="$test_root/project"
home="$test_root/home"
state="$test_root/state"
fake_bin="$test_root/fake-bin"
etc_root="$test_root/etc-root"
mkdir -p "$project/tools/local-server" "$project/database" "$home" "$fake_bin" "$etc_root/etc/php/conf.d"

printf '8.5\n' >"$project/.php-version"
printf '24.18.0\n' >"$project/.node-version"
printf '%s\n' '{"packageManager":"pnpm@11.3.0","scripts":{"check":"true"}}' >"$project/package.json"
printf '%s\n' '{"scripts":{"setup":"true","server:check":"true","check":"true","dev":"true"}}' >"$project/composer.json"
printf '%s\n' 'extension=bcmath' 'extension=gd' 'extension=intl' 'extension=pdo_sqlite' 'extension=sqlite3' \
  >"$project/tools/local-server/php-extensions.ini"
printf 'sqlite fixture\n' >"$project/database/database.sqlite"

profile="$project/bloody-writer.workspace.json"
jq -n '{
  "$schema":"https://example.invalid/workspace-v1.json",
  schema_version:1,
  profile:{id:"test-project",display_name:"Test project",minimum_bloody_writer_version:"0.3.0",review_state:"approved"},
  platform:{distribution:"arch",environment:"wsl",wsl_version:2},
  packages:{pacman:["composer","php"],npm_global:["workspace-provider"]},
  versions:{php:{source:".php-version",requirement:"8.5"},node:{source:".node-version",requirement:"24.18.0"},pnpm:{source:"package.json",requirement:"11.3.0"}},
  requirements:{binaries:["composer","php","pnpm"],php_extensions:["bcmath","gd","intl","pdo_sqlite","sqlite3"]},
  system_files:[{adapter:"php-conf",source:"tools/local-server/php-extensions.ini",destination:"/etc/php/conf.d/20-test.ini"}],
  environment_guard:{app_env:"local",app_url_scope:"loopback",db_connection:"sqlite",sqlite_backup:true},
  lifecycle:{setup:[{argv:["composer","run","setup","$(touch should-not-exist)"]}],verify:[{argv:["composer","check"]},{argv:["pnpm","run","check"]}],development:{argv:["composer","run","dev"]}},
  ports:[{host:"127.0.0.1",port:8080,purpose:"test"}],
  capabilities:{bloody_writer_base:true}
}' >"$profile"

git -C "$project" init -q -b main
git -C "$project" config user.name 'Workspace Tests'
git -C "$project" config user.email 'tests@example.invalid'
git -C "$project" remote add origin git@github.com:owner/private-project.git
git -C "$project" add .
git -C "$project" commit -q -m 'fixture: approved workspace'

command_log="$test_root/commands.log"
cat >"$fake_bin/composer" <<'EOF'
#!/usr/bin/env bash
printf 'composer TMPDIR=%s' "${TMPDIR:-}" >>"$BW_TEST_COMMAND_LOG"
printf ' <%s>' "$@" >>"$BW_TEST_COMMAND_LOG"
printf '\n' >>"$BW_TEST_COMMAND_LOG"
[[ ${BW_TEST_FAIL_SETUP:-0} != 1 || " $* " != *' run setup '* ]]
EOF
cat >"$fake_bin/pnpm" <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == --version ]]; then
  printf '11.3.0\n'
  exit 0
fi
printf 'pnpm TMPDIR=%s' "${TMPDIR:-}" >>"$BW_TEST_COMMAND_LOG"
printf ' <%s>' "$@" >>"$BW_TEST_COMMAND_LOG"
printf '\n' >>"$BW_TEST_COMMAND_LOG"
EOF
cat >"$fake_bin/node" <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == --version ]]; then
  printf 'v24.18.0\n'
  exit 0
fi
printf 'Unexpected fake Node invocation in workspace test.\n' >&2
exit 64
EOF
cat >"$fake_bin/php" <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == -m ]]; then
  printf '%s\n' bcmath gd intl pdo_sqlite sqlite3
elif [[ ${1:-} == -r ]]; then
  printf '8.5'
fi
EOF
cat >"$fake_bin/npm" <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == list && ${2:-} == --global ]]; then
  count=0
  [[ ! -f $BW_TEST_NPM_QUERY_COUNT ]] || count="$(<"$BW_TEST_NPM_QUERY_COUNT")"
  printf '%s\n' "$((count + 1))" >"$BW_TEST_NPM_QUERY_COUNT"
  if [[ ${BW_TEST_NPM_MISSING:-0} == 1 ]]; then
    printf '%s\n' '{"dependencies":{}}'
  else
    printf '%s\n' '{"dependencies":{"workspace-provider":{"version":"1.0.0"}}}'
  fi
  exit 0
fi
exit 0
EOF
cat >"$fake_bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == -Qq ]]; then
  package="${!#}"
  grep -Fxq -- "$package" "$BW_WORKSPACE_INSTALLED_PACKAGES_FILE"
elif [[ ${1:-} == -Qqe ]]; then
  cat "$BW_WORKSPACE_SCAN_EXPLICIT_PACKAGES_FILE"
elif [[ ${1:-} == -Qqo ]]; then
  executable="$(basename -- "${!#}")"
  case "$executable" in
  gh) printf 'github-cli\n' ;;
  node) printf 'nodejs-lts-krypton\n' ;;
  rg) printf 'ripgrep\n' ;;
  *) printf '%s\n' "$executable" ;;
  esac
else
  exit 0
fi
EOF
chmod +x "$fake_bin"/*
printf '%s\n' composer dependency-only php >"$test_root/installed-packages"
printf '%s\n' workspace-provider >"$test_root/installed-npm"
: >"$test_root/npm-query-count"

export HOME="$home"
export XDG_STATE_HOME="$state"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_CACHE_HOME="$test_root/cache"
export BW_STATE_DIR="$state/bloody-writer"
export BW_CONFIG_DIR="$test_root/config/bloody-writer"
export BW_CACHE_DIR="$test_root/cache/bloody-writer"
export BW_TEST_MODE=1
export BW_PLATFORM=wsl
export BW_WORKSPACE_ETC_ROOT="$etc_root"
export BW_WORKSPACE_INSTALLED_PACKAGES_FILE="$test_root/installed-packages"
export BW_WORKSPACE_INSTALLED_NPM_FILE="$test_root/installed-npm"
export BW_TEST_COMMAND_LOG="$command_log"
export BW_TEST_NPM_QUERY_COUNT="$test_root/npm-query-count"
export PATH="$fake_bin:$PATH"

for phase in 00-preflight 10-system 20-packages 25-host-theme 30-shell 40-dotfiles 50-neovim 60-codex 70-github 90-verify; do
  mkdir -p "$BW_STATE_DIR/completed"
  : >"$BW_STATE_DIR/completed/$phase"
done

validate_output="$("$repo_root/bin/bloody-writer" workspace validate "$profile")"
grep -q 'valid and approved' <<<"$validate_output"

apply_output="$("$repo_root/bin/bloody-writer" workspace apply "$profile" --yes)"
grep -q 'base and workspace profile are complete' <<<"$apply_output"
# shellcheck disable=SC2016
grep -q 'composer.*<run> <setup> <$(touch should-not-exist)>' "$command_log"
grep -q 'TMPDIR=/tmp' "$command_log"
[[ ! -e $project/should-not-exist ]]
cmp -s "$project/tools/local-server/php-extensions.ini" "$etc_root/etc/php/conf.d/20-test.ini"

digest="$(sha256sum "$profile" | awk '{print $1}')"
generation="$BW_STATE_DIR/workspaces/test-project/$digest"
for phase in workspace-packages workspace-system-files workspace-project-setup workspace-verify; do
  [[ -f $generation/completed/$phase ]]
done
[[ -f $generation/backups/sqlite/database.sqlite.before-setup ]]
[[ $(stat -c %a "$BW_STATE_DIR/workspaces/active.json") == 600 ]]

status_output="$("$repo_root/bin/bloody-writer" workspace status)"
grep -q 'Active workspace: test-project' <<<"$status_output"
grep -q 'workspace-verify.*complete' <<<"$status_output"
"$repo_root/bin/bloody-writer" workspace resume --yes >/dev/null

# A changed manifest creates a new generation and failed phases are never marked complete.
jq '.profile.display_name="Changed test project"' "$profile" >"$profile.next"
mv "$profile.next" "$profile"
git -C "$project" add "$profile"
git -C "$project" commit -q -m 'test: change manifest generation'
new_digest="$(sha256sum "$profile" | awk '{print $1}')"
if BW_TEST_FAIL_SETUP=1 "$repo_root/bin/bloody-writer" workspace apply "$profile" --yes >/dev/null 2>&1; then
  printf 'Workspace apply unexpectedly passed a failed lifecycle command.\n' >&2
  exit 1
fi
[[ -f $BW_STATE_DIR/workspaces/test-project/$new_digest/completed/workspace-system-files ]]
[[ ! -e $BW_STATE_DIR/workspaces/test-project/$new_digest/completed/workspace-project-setup ]]
BW_TEST_FAIL_SETUP=0 "$repo_root/bin/bloody-writer" workspace resume --yes >/dev/null
[[ -f $BW_STATE_DIR/workspaces/test-project/$new_digest/completed/workspace-verify ]]

# Differing destinations are preserved under the exact profile generation.
printf 'old system bytes\n' >"$etc_root/etc/php/conf.d/20-test.ini"
"$repo_root/bin/bloody-writer" workspace apply "$profile" --yes --force >/dev/null
grep -q 'old system bytes' "$BW_STATE_DIR/workspaces/test-project/$new_digest/backups/system-files/etc/php/conf.d/20-test.ini"

# The local-only guard reads selected values without sourcing .env.
# shellcheck disable=SC2016
printf '%s\n' 'APP_ENV=production' 'APP_URL=https://example.com' 'DB_CONNECTION=mysql' 'BAD=$(touch env-was-sourced)' >"$project/.env"
if "$repo_root/bin/bloody-writer" workspace apply "$profile" --yes --force >/dev/null 2>&1; then
  printf 'Unsafe project environment unexpectedly passed.\n' >&2
  exit 1
fi
[[ ! -e $project/env-was-sourced ]]
printf '%s\n' 'APP_ENV=local' 'APP_URL=http://127.0.0.1:8080' 'DB_CONNECTION=sqlite' >"$project/.env"

audit_output="$("$repo_root/bin/bloody-writer" workspace audit "$profile")"
grep -q '\[ok\] system file' <<<"$audit_output"
grep -q '\[ok\] global npm package workspace-provider' <<<"$audit_output"
[[ $(<"$BW_TEST_NPM_QUERY_COUNT") == 1 ]]
if missing_npm_output="$(BW_TEST_NPM_MISSING=1 "$repo_root/bin/bloody-writer" workspace audit "$profile" 2>&1)"; then
  printf 'Workspace audit unexpectedly accepted a missing global npm package.\n' >&2
  exit 1
fi
grep -q '\[missing\] global npm package workspace-provider' <<<"$missing_npm_output"
[[ $(<"$BW_TEST_NPM_QUERY_COUNT") == 2 ]]

expect_rejected() {
  local label="$1" expression="$2"
  local bad="$project/bad-$label.json"
  jq "$expression" "$profile" >"$bad"
  git -C "$project" add "$bad"
  git -C "$project" commit -q -m "test: add bad $label"
  if "$repo_root/bin/bloody-writer" workspace validate "$bad" >/dev/null 2>&1; then
    printf 'Invalid profile unexpectedly passed: %s\n' "$label" >&2
    exit 1
  fi
}

expect_rejected unknown-key '.unexpected=true'
expect_rejected unknown-schema '.schema_version=2'
expect_rejected candidate '.profile.review_state="candidate"'
expect_rejected unsafe-package '.packages.pacman=["bad;package"]'
expect_rejected unsorted '.packages.pacman=["php","composer"]'
expect_rejected duplicate '.packages.pacman=["composer","composer"]'
expect_rejected traversal '.system_files[0].source="../secret.ini"'
expect_rejected destination '.system_files[0].destination="/etc/passwd"'
expect_rejected adapter '.system_files[0].adapter="unrestricted-copy"'
expect_rejected version-drift '.versions.php.requirement="8.4"'
expect_rejected shell-delegation '.lifecycle.setup[0].argv=["sh","-c","touch delegated"]'
expect_rejected wrapper-delegation '.lifecycle.setup[0].argv=["env","bash","-c","touch delegated"]'
expect_rejected executable-path '.lifecycle.setup[0].argv[0]="/usr/bin/composer"'
expect_rejected control-argument '.lifecycle.setup[0].argv[1]="bad\nargument"'

command_lines_before="$(wc -l <"$command_log")"
jq '.scripts.uncommitted="must block"' "$project/composer.json" >"$project/composer.json.next"
mv "$project/composer.json.next" "$project/composer.json"
if "$repo_root/bin/bloody-writer" workspace validate "$profile" >/dev/null 2>&1; then
  printf 'Modified composer.json unexpectedly passed lifecycle validation.\n' >&2
  exit 1
fi
if "$repo_root/bin/bloody-writer" workspace apply "$profile" --yes --force >/dev/null 2>&1; then
  printf 'Modified composer.json unexpectedly reached workspace apply.\n' >&2
  exit 1
fi
[[ $(wc -l <"$command_log") == "$command_lines_before" ]]
git -C "$project" restore -- composer.json

printf '{broken json\n' >"$project/malformed.json"
git -C "$project" add malformed.json
git -C "$project" commit -q -m 'test: add malformed profile'
if "$repo_root/bin/bloody-writer" workspace validate "$project/malformed.json" >/dev/null 2>&1; then
  printf 'Malformed profile unexpectedly passed.\n' >&2
  exit 1
fi

head -c 1048577 /dev/zero | tr '\0' x >"$project/oversized.json"
git -C "$project" add oversized.json
git -C "$project" commit -q -m 'test: add oversized profile'
if "$repo_root/bin/bloody-writer" workspace validate "$project/oversized.json" >/dev/null 2>&1; then
  printf 'Oversized profile unexpectedly passed.\n' >&2
  exit 1
fi

printf 'untracked source\n' >"$project/untracked.ini"
jq '.system_files[0].source="untracked.ini"' "$profile" >"$project/untracked-source.json"
git -C "$project" add untracked-source.json
git -C "$project" commit -q -m 'test: add untracked source profile'
if "$repo_root/bin/bloody-writer" workspace validate "$project/untracked-source.json" >/dev/null 2>&1; then
  printf 'Untracked system-file source unexpectedly passed.\n' >&2
  exit 1
fi

ln -s tools/local-server/php-extensions.ini "$project/symlink.ini"
jq '.system_files[0].source="symlink.ini"' "$profile" >"$project/symlink-source.json"
git -C "$project" add symlink.ini symlink-source.json
git -C "$project" commit -q -m 'test: add symlink source profile'
if "$repo_root/bin/bloody-writer" workspace validate "$project/symlink-source.json" >/dev/null 2>&1; then
  printf 'Symlink system-file source unexpectedly passed.\n' >&2
  exit 1
fi

untracked="$project/untracked-profile.json"
cp "$profile" "$untracked"
if "$repo_root/bin/bloody-writer" workspace validate "$untracked" >/dev/null 2>&1; then
  printf 'Untracked profile unexpectedly passed.\n' >&2
  exit 1
fi
ln -s "$profile" "$project/profile-link.json"
if "$repo_root/bin/bloody-writer" workspace validate "$project/profile-link.json" >/dev/null 2>&1; then
  printf 'Symlink profile unexpectedly passed.\n' >&2
  exit 1
fi

# Scanner output is deterministic, candidate-only, excludes private/machine state, and never overwrites.
printf '%s\n' base-devel composer git github-cli jq keychain nginx nodejs-lts-krypton npm php php-fpm php-gd php-sqlite pnpm python ripgrep >"$test_root/scan-explicit-packages"
printf '%s\n' custom-provider neovim pacman-owned-provider >"$test_root/scan-npm"
printf '%s\n' pacman-owned-provider >"$test_root/scan-pacman-owned-npm"
export BW_WORKSPACE_SCAN_EXPLICIT_PACKAGES_FILE="$test_root/scan-explicit-packages"
export BW_WORKSPACE_SCAN_NPM_FILE="$test_root/scan-npm"
export BW_WORKSPACE_SCAN_PACMAN_OWNED_NPM_FILE="$test_root/scan-pacman-owned-npm"
cp "$project/tools/local-server/php-extensions.ini" "$etc_root/etc/php/conf.d/20-ce-systems.ini"
scan_one="$test_root/scan-one.json"
scan_two="$test_root/scan-two.json"
"$repo_root/bin/bloody-writer" workspace scan --project "$project" --output "$scan_one" >/dev/null
"$repo_root/bin/bloody-writer" workspace scan --project "$project" --output "$scan_two" >/dev/null
cmp -s "$scan_one" "$scan_two"
jq -e '.profile.review_state=="candidate" and (.packages.npm_global|index("custom-provider"))' "$scan_one" >/dev/null
jq -e '(.packages.npm_global|index("neovim")|not) and (.packages.npm_global|index("pacman-owned-provider")|not)' "$scan_one" >/dev/null
jq -e '(.packages.pacman|index("tree")) and (.packages.pacman|index("dependency-only")|not)' "$scan_one" >/dev/null
if rg -n 'APP_ENV|sqlite fixture|env-was-sourced|\.idea|obsidian|/home/|/root/|history|hostname|username' "$scan_one"; then
  printf 'Scanner captured excluded private or machine-specific state.\n' >&2
  exit 1
fi
if "$repo_root/bin/bloody-writer" workspace scan --project "$project" --output "$scan_one" >/dev/null 2>&1; then
  printf 'Scanner unexpectedly overwrote an existing profile.\n' >&2
  exit 1
fi
: >"$test_root/scan-npm-empty"
BW_WORKSPACE_SCAN_NPM_FILE="$test_root/scan-npm-empty" \
  "$repo_root/bin/bloody-writer" workspace scan --project "$project" --output "$test_root/scan-empty-npm.json" >/dev/null
jq -e '.packages.npm_global == []' "$test_root/scan-empty-npm.json" >/dev/null

missing_rg_output="$(
  (
    BW_REPO_ROOT="$repo_root" BW_TEST_MODE=1 BW_PLATFORM=wsl bash -c '
      source "$BW_REPO_ROOT/scripts/lib/common.sh"
      source "$BW_REPO_ROOT/scripts/lib/workspace.sh"
      bw_have() { [[ $1 != rg ]] && command -v "$1" >/dev/null 2>&1; }
      bw_workspace_scan_command --project "$1" --output "$2"
    ' _ "$project" "$test_root/no-rg-output.json"
  ) 2>&1 || true
)"
grep -q 'ripgrep (rg) is required for the curated workspace scanner' <<<"$missing_rg_output"
[[ ! -e $test_root/no-rg-output.json ]]

# Termux rejects the workspace layer before creating state.
termux_state="$test_root/termux-state"
if BW_PLATFORM=termux BW_STATE_DIR="$termux_state" "$repo_root/bin/bloody-writer" workspace validate "$profile" >/dev/null 2>&1; then
  printf 'Termux unexpectedly accepted a workspace profile.\n' >&2
  exit 1
fi
[[ ! -e $termux_state ]]
if BW_PLATFORM=termux BW_STATE_DIR="$termux_state" "$repo_root/bin/bloody-writer" install --workspace "$profile" --yes >/dev/null 2>&1; then
  printf 'Termux unexpectedly began an install with a workspace profile.\n' >&2
  exit 1
fi
[[ ! -e $termux_state ]]

unsupported_state="$test_root/unsupported-state"
if BW_PLATFORM=unsupported BW_STATE_DIR="$unsupported_state" "$repo_root/bin/bloody-writer" workspace apply "$profile" --yes >/dev/null 2>&1; then
  printf 'Unsupported Linux unexpectedly accepted a workspace profile.\n' >&2
  exit 1
fi
[[ ! -e $unsupported_state ]]

root_state="$test_root/root-state"
root_guidance="$(BW_WORKSPACE_TEST_ROOT=1 BW_STATE_DIR="$root_state" "$repo_root/bin/bloody-writer" workspace apply "$profile" --yes 2>&1 || true)"
grep -q 'cannot run as root' <<<"$root_guidance"
grep -q 'gh repo clone owner/private-project ~/projects/project' <<<"$root_guidance"
grep -q 'workspace apply ~/projects/project/bloody-writer.workspace.json' <<<"$root_guidance"
grep -q 'will not copy a private project or credentials out of /root' <<<"$root_guidance"
[[ ! -e $root_state ]]

dry_state="$test_root/dry-state"
dry_output="$(BW_STATE_DIR="$dry_state" "$repo_root/bin/bloody-writer" workspace apply "$profile" --dry-run)"
grep -q 'preview complete' <<<"$dry_output"
[[ ! -e $dry_state/workspaces ]]

printf 'Workspace profile tests passed.\n'
