#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

seed="$test_root/seed"
remote="$test_root/remote.git"
device="$test_root/device"
publisher="$test_root/publisher"
mkdir -p "$seed"

# Build the fixture from the current working tree so the test works before the change is committed.
tar -C "$repo_root" --exclude=.git -cf - . | tar -C "$seed" -xf -
git -C "$seed" init -q -b main
git -C "$seed" config user.name 'Bloody Writer Tests'
git -C "$seed" config user.email 'tests@example.invalid'
git -C "$seed" add .
git -C "$seed" commit -q -m 'fixture: current checkout'
git clone -q --bare "$seed" "$remote"
git clone -q "$remote" "$device"
git clone -q "$remote" "$publisher"

git -C "$publisher" config user.name 'Bloody Writer Tests'
git -C "$publisher" config user.email 'tests@example.invalid'
sed -i 's/BLOODY_WRITER_VERSION="[^"]*"/BLOODY_WRITER_VERSION="9.9.9-test"/' \
  "$publisher/versions.env"
git -C "$publisher" add versions.env
git -C "$publisher" commit -q -m 'test: publish a newer installer'
git -C "$publisher" push -q origin main

lockfile="$device/dotfiles/nvim/.config/nvim/lazy-lock.json"
printf '\n' >>"$lockfile"

device_home="$test_root/home"
mkdir -p "$device_home"
update_output="$(
  HOME="$device_home" \
    XDG_STATE_HOME="$test_root/state" \
    XDG_CONFIG_HOME="$test_root/config" \
    XDG_CACHE_HOME="$test_root/cache" \
    BW_TEST_MODE=1 \
    BW_PLATFORM=termux \
    "$device/bin/bloody-writer" update --yes --only 90-verify 2>&1
)"

grep -q 'Repairing generated runtime drift before updating' <<<"$update_output"
grep -q 'Continuing with the freshly updated installer' <<<"$update_output"
grep -q '^version=9.9.9-test$' \
  "$test_root/state/bloody-writer/completed/90-verify"
[[ -z $(git -C "$device" status --short) ]]
find "$test_root/state/bloody-writer/update-recovery" \
  -type f -path '*/files/dotfiles/nvim/.config/nvim/lazy-lock.json' -print -quit |
  grep -q .
find "$test_root/state/bloody-writer/update-recovery" \
  -type f -name generated-drift.patch -print -quit |
  grep -q .

printf '\nlocal documentation draft\n' >>"$device/README.md"
if protected_output="$(
  HOME="$device_home" \
    XDG_STATE_HOME="$test_root/state" \
    XDG_CONFIG_HOME="$test_root/config" \
    XDG_CACHE_HOME="$test_root/cache" \
    BW_TEST_MODE=1 \
    BW_PLATFORM=termux \
    "$device/bin/bloody-writer" update --yes --only 90-verify 2>&1
)"; then
  printf 'Update unexpectedly overwrote an authored checkout change.\n' >&2
  exit 1
fi
grep -q 'README.md' <<<"$protected_output"
grep -q 'were preserved' <<<"$protected_output"
grep -q 'local documentation draft' "$device/README.md"

printf 'Self-healing update test passed.\n'
