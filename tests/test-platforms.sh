#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

export HOME="$test_root/home"
export XDG_STATE_HOME="$test_root/state"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$test_root/cache"
export BW_STATE_DIR="$XDG_STATE_HOME/bloody-writer"
export BW_CONFIG_DIR="$XDG_CONFIG_HOME/bloody-writer"
export BW_CACHE_DIR="$XDG_CACHE_HOME/bloody-writer"
export BW_TEST_MODE=1
export BW_PLATFORM=termux

mkdir -p "$HOME"
install_output="$("$repo_root/bin/bloody-writer" install --yes 2>&1)"

for phase in \
  00-preflight 10-system 20-packages 25-host-theme 30-shell 40-dotfiles \
  50-neovim 60-codex 70-github 90-verify; do
  [[ -f $BW_STATE_DIR/completed/$phase ]]
done

status_output="$("$repo_root/bin/bloody-writer" status)"
grep -q 'Platform: Termux on Android' <<<"$status_output"
grep -q '25-host-theme.*complete' <<<"$status_output"
grep -q 'All installation phases completed successfully' <<<"$install_output"
grep -q 'Fully close the Termux app, then reopen it once' <<<"$install_output"

no_op_output="$("$repo_root/bin/bloody-writer" install --yes 2>&1)"
grep -q 'Termux configuration was already complete; no app restart is required' <<<"$no_op_output"
if grep -q 'Fully close the Termux app' <<<"$no_op_output"; then
  printf 'No-op installation incorrectly requested a Termux app restart.\n' >&2
  exit 1
fi

help_output="$("$repo_root/install.sh" --help)"
grep -q 'Windows WSL 2' <<<"$help_output"
grep -q 'Termux on Android' <<<"$help_output"
grep -q -- '--skip-host-theme' <<<"$help_output"
grep -q 'Pause and resume' <<<"$help_output"

# The single-quoted programs expand inside the child Bash processes.
# shellcheck disable=SC2016
detected_termux="$(
  env -u BW_PLATFORM PREFIX=/data/data/com.termux/files/usr \
    BW_REPO_ROOT="$repo_root" BW_TEST_MODE=1 bash -c \
    'source "$BW_REPO_ROOT/scripts/lib/common.sh"; printf "%s" "$BW_PLATFORM"'
)"
[[ $detected_termux == termux ]]

printf 'Finish the Android permission prompt, then rerun ./install.sh.\n' \
  >"$BW_STATE_DIR/manual/test-checkpoint"
status_output="$("$repo_root/bin/bloody-writer" status)"
grep -q 'Manual checkpoint: Finish the Android permission prompt' <<<"$status_output"
rm -- "$BW_STATE_DIR/manual/test-checkpoint"

# shellcheck disable=SC2016
if BW_ASSUME_YES=1 BW_REPO_ROOT="$repo_root" bash -c \
  'source "$BW_REPO_ROOT/scripts/lib/common.sh"; bw_confirm_manual "Did the host action finish?"' \
  </dev/null 2>/dev/null; then
  printf '%s\n' '--yes incorrectly bypassed a manual host checkpoint.' >&2
  exit 1
fi

mkdir -p "$test_root/fake-bin" "$test_root/dry-home"
: >"$test_root/fake-bin/pkg"
chmod +x "$test_root/fake-bin/pkg"
dry_output="$(
  env -u BW_PLATFORM \
    HOME="$test_root/dry-home" \
    PREFIX=/data/data/com.termux/files/usr \
    PATH="$test_root/fake-bin:$PATH" \
    BW_TEST_MODE=0 \
    BW_STATE_DIR="$test_root/dry-home/.local/state/bloody-writer" \
    BW_CONFIG_DIR="$test_root/dry-home/.config/bloody-writer" \
    BW_CACHE_DIR="$test_root/dry-home/.cache/bloody-writer" \
    "$repo_root/install.sh" --dry-run --yes
)"
grep -q 'Would verify Android shared storage' <<<"$dry_output"
grep -q 'Would verify the matching-source Termux:API' <<<"$dry_output"
grep -q 'JetBrainsMonoNerdFontMono-Regular.ttf' <<<"$dry_output"
grep -q 'Preview complete; no state was changed' <<<"$dry_output"
if grep -q 'Fully close the Termux app' <<<"$dry_output"; then
  printf 'Dry-run output incorrectly requested a Termux app restart.\n' >&2
  exit 1
fi

incomplete_home="$test_root/incomplete-home"
mkdir -p "$incomplete_home"
incomplete_output="$(
  HOME="$incomplete_home" \
    BW_STATE_DIR="$incomplete_home/.local/state/bloody-writer" \
    BW_CONFIG_DIR="$incomplete_home/.config/bloody-writer" \
    BW_CACHE_DIR="$incomplete_home/.cache/bloody-writer" \
    BW_TEST_MODE=1 BW_PLATFORM=termux \
    "$repo_root/install.sh" --yes --skip-github 2>&1
)"
if grep -q 'Fully close the Termux app' <<<"$incomplete_output"; then
  printf 'Incomplete installation incorrectly requested a Termux app restart.\n' >&2
  exit 1
fi

printf 'Platform detection and help test passed.\n'
