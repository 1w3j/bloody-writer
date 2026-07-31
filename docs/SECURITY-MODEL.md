# Security model

## Public-repository rule

This repository may contain configuration, public screenshots, and upstream identifiers. It must
never contain private SSH keys/passphrases, access tokens, Codex authentication/sessions/state,
GitHub CLI `hosts.yml`, histories, downloaded caches, personal documents, private repositories,
customer data, or machine-specific paths.

`tests/security-scan.sh` rejects common credential formats and known personal snapshot paths.
Humans must also inspect screenshot pixels; text scans cannot see visual leaks.

## Privilege boundary

| Environment | Boundary |
|---|---|
| Arch Linux on Windows WSL | Root bootstrap plus explicit system/package `sudo`; dotfiles, keys, Codex, and GitHub remain normal-user owned |
| Termux on Android | Root is rejected; `pkg` and all files run as the Android app user; no `sudo` |
| Windows host | PowerShell helper installs a current-user font/fragment; it does not rewrite global Terminal settings |
| Android host | Permission/app checkpoints remain Android-owned and require visible user action |

The installer never stores a sudo password or creates passwordless sudo.

## Download boundary

- Arch and Termux packages come from their configured repositories.
- Oh My Zsh uses the reviewed commit in `versions.env`.
- Neovim plugins are seeded from the reviewed `lazy-lock.json` into device-local state and rebuilt
  locally for each architecture. Only the explicit maintainer helper writes the tracked lock.
- Spell files and the Nerd Font use pinned SHA-256 checksums.
- WSL Codex uses OpenAI's official standalone installer and release pin.
- No unofficial Android Codex executable is installed.

Review upstream changes before updating pins.

## Existing data and destructive actions

Conflicting managed paths move into a timestamped backup before symlinks are created. Restore
validates targets under the expected home/state roots. Updates require a clean checkout and use
fast-forward-only pulls.

`tma` attach is non-destructive. Killing a session ends every process inside it, so both the fzf
and fallback paths show an explicit one-key confirmation and use an exact tmux target.

## Remote boundary

Tailscale SSH is opt-in and does not open the router's public port 22. Bloody Writer does not alter
Windows power settings, silently create an always-on task, weaken SSH policy, or migrate private
keys between Android and WSL. Tailnet identity, ACL/SSH rules, device revocation, and host uptime
remain user-controlled.
