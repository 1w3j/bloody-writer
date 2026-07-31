#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/bin"

export TMA_FAKE_STATE="$test_root/state"
export TMA_FAKE_LOG="$test_root/log"
printf 'writer\n' >"$TMA_FAKE_STATE"

apply_fake_tmux="$test_root/bin/tmux"
cp "$repo_root/tests/fixtures/fake-tmux.sh" "$apply_fake_tmux"
chmod +x "$apply_fake_tmux"

tma="$repo_root/dotfiles/local-bin/.local/bin/tma"
help_output="$(PATH="$test_root/bin:$PATH" "$tma" --help)"
grep -q 'Ctrl-X' <<<"$help_output"
grep -q 'confirmation' <<<"$help_output"
grep -q 'Termux on Android' <<<"$help_output"

printf 'n' | PATH="$test_root/bin:$PATH" "$tma" --kill writer
grep -qx writer "$TMA_FAKE_STATE"
[[ ! -e $TMA_FAKE_LOG ]]

printf 'y' | PATH="$test_root/bin:$PATH" "$tma" --kill writer
[[ ! -s $TMA_FAKE_STATE ]]
grep -qx 'kill =writer' "$TMA_FAKE_LOG"

if printf 'y' | PATH="$test_root/bin:$PATH" "$tma" --kill missing 2>/dev/null; then
  printf 'tma accepted a missing exact session target.\n' >&2
  exit 1
fi

printf 'tma help and confirmed-kill test passed.\n'
