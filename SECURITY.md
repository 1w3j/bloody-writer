# Security policy

## Supported version

Security fixes are applied to the current `main` branch and latest tagged release.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting feature for this repository. Do not include live
tokens, private keys, passphrases, personal documents, or third-party secrets in a report.

For an accidentally committed secret:

1. Revoke or rotate it immediately.
2. Remove it from the working tree and Git history.
3. Review GitHub, Codex, SSH, and package-provider logs for misuse.
4. Report the incident privately.

Deleting a secret from the latest commit is not sufficient after it has been published.

## Installer trust

Read `scripts/phases/` before running the installer on a sensitive machine. The project targets
fresh Arch WSL instances, performs privileged work in foreground phases, and backs up conflicting
dotfiles. See [the security model](docs/SECURITY-MODEL.md).
