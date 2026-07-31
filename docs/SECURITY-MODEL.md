# Security model

## Public-repository rule

This repository may contain configuration and public upstream identifiers. It must never contain:

- Private SSH keys or passphrases.
- GitHub, OpenAI, npm, or other access tokens.
- Codex `auth.json`, installation IDs, state databases, session logs, or attachments.
- GitHub CLI `hosts.yml`.
- Shell history, known-host history, caches, or downloaded plugin state.
- Personal documents, private repositories, customer data, or machine-specific paths.

The automated secret scan in `tests/security-scan.sh` rejects common credential formats and
known personal snapshot paths.

## Privilege boundary

Only system and package phases use sudo. Dotfiles, plugins, SSH keys, Codex state, and GitHub
configuration remain owned by the normal user.

Commands requiring sudo are visible in phase scripts and run in the foreground. The installer
does not store a sudo password or create passwordless sudo.

## Download boundary

- Arch packages come from configured pacman repositories.
- Oh My Zsh is checked out at the commit in `versions.env`.
- Neovim plugins are locked by `lazy-lock.json`.
- Spell files are verified with SHA-256.
- Codex is installed by OpenAI's official standalone installer, which verifies release digests.

Review upstream changes before updating pins.

## Existing data

Conflicting dotfiles are moved to a timestamped backup before symlinks are created. The updater
requires a clean Git checkout and uses fast-forward-only pulls.

The root bootstrap is intentionally limited to a fresh Arch WSL instance. It never unregisters
a distribution, changes Windows power policy, or automatically terminates WSL.
