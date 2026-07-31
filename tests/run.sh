#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$repo_root"

printf 'Checking Bash syntax...\n'
while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(find . -type f -name '*.sh' -print0)

printf 'Checking Zsh syntax...\n'
zsh -n dotfiles/zsh/.zshrc

printf 'Running ShellCheck...\n'
mapfile -d '' shell_files < <(find . -type f -name '*.sh' -print0)
shellcheck -x "${shell_files[@]}"

printf 'Parsing JSON...\n'
jq empty terminal/bloody-writer.json
jq empty dotfiles/nvim/.config/nvim/lazy-lock.json

printf 'Checking package manifests...\n'
for manifest in manifests/arch-packages.txt manifests/npm-globals.txt manifests/termux-packages.txt; do
  entries="$(sed -E '/^[[:space:]]*(#|$)/d' "$manifest")"
  [[ -n $entries ]]
  diff -u <(printf '%s\n' "$entries") <(printf '%s\n' "$entries" | LC_ALL=C sort -u)
done

printf 'Checking executable files...\n'
for file in install.sh bin/bloody-writer scripts/bootstrap-root.sh scripts/doctor.sh \
  scripts/setup-remote.sh dotfiles/local-bin/.local/bin/tma tests/run.sh \
  dotfiles/local-bin/.local/bin/bw-clipboard-copy tests/test-platforms.sh \
  tests/test-powershell.sh tests/test-tma.sh \
  tests/security-scan.sh tests/test-doc-links.sh tests/test-linker.sh tests/test-resume.sh; do
  [[ -x $file ]] || {
    printf 'Expected executable bit: %s\n' "$file" >&2
    exit 1
  }
done

tests/security-scan.sh
tests/test-doc-links.sh
tests/test-linker.sh
tests/test-resume.sh
tests/test-platforms.sh
tests/test-tma.sh
tests/test-powershell.sh

printf 'Checking public image assets...\n'
for image in \
  assets/brand/bloody-writer-logo.png \
  assets/screenshots/wsl-hero.png \
  assets/screenshots/wsl-cheatsheet.png \
  assets/screenshots/tmux-session-picker.png; do
  [[ -s $image ]]
done

printf 'Checking whitespace...\n'
git diff --check

printf 'All tests passed.\n'
