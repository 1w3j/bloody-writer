#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
if ! command -v pwsh >/dev/null 2>&1; then
  printf 'PowerShell parser unavailable; skipped Windows script parse check.\n'
  exit 0
fi

for file in windows/bootstrap-wsl.ps1 windows/apply-host-theme.ps1; do
  # The single-quoted program is PowerShell, not Bash.
  # shellcheck disable=SC2016
  PS_FILE="$repo_root/$file" pwsh -NoLogo -NoProfile -Command '
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
      $env:PS_FILE,
      [ref]$tokens,
      [ref]$errors
    ) | Out-Null
    if ($errors.Count -gt 0) {
      $errors | ForEach-Object { [Console]::Error.WriteLine($_.Message) }
      exit 1
    }
  '
done

printf 'PowerShell syntax test passed.\n'
