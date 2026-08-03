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

## Workspace-profile trust boundary

Workspace JSON is untrusted until it passes exact-key/type/value checks, is an approved profile
inside a Git repository, and the user sees its project root, commit, and SHA-256 before confirming.
Termux, root, non-Arch WSL, symlinked profiles/sources, path traversal, untracked sources, unsafe
package names, unknown schema versions/keys, and unsupported destinations stop before mutation.

Version 1 may write only PHP fragments under `/etc/php/conf.d/` through its defined adapter.
Commands are structured argument arrays run directly, never shell expressions. Shell/privilege
wrappers, path-qualified executables, and control characters are rejected, while Composer and
Node package-manager indirection requires its tracked manifest to be regular and committed-clean.
Before project
setup, the installer reads only selected local guard values from `.env` without sourcing it; it
requires `APP_ENV=local`, SQLite, and a loopback application URL, then preserves an existing
SQLite database in private workspace state.

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

Workspace scanning is deliberately curated rather than a home-directory snapshot. It never
serializes `.env`, databases, ignored/private evidence, IDE state, credentials, Git identity,
Codex/GitHub sessions, SSH keys, history, caches, dependencies, logs, tmux sessions, user/host
identity, absolute home paths, or Obsidian destinations.

## Remote boundary

Tailscale SSH is opt-in and does not open the router's public port 22. Bloody Writer does not alter
Windows power settings, silently create an always-on task, weaken SSH policy, or migrate private
keys between Android and WSL. Tailnet identity, ACL/SSH rules, device revocation, and host uptime
remain user-controlled.
