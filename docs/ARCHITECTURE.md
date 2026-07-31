# Architecture and state model

## Layer map

```text
Windows host
├── WSL 2 and Arch distribution
├── Windows Terminal + Nerd Font (manual host layer)
└── Android/Tailscale (optional remote client)

Arch WSL
├── pacman packages
├── ~/.oh-my-zsh                    pinned external checkout
├── ~/bloody-writer                 Git source of truth
│   ├── dotfiles/
│   ├── scripts/phases/
│   ├── terminal/
│   └── docs/
├── ~/.zshrc                        symlink into repository
├── ~/.tmux.conf                    symlink into repository
├── ~/.config/nvim                  symlink into repository
├── ~/.config/bloody-writer         personal, untracked settings
├── ~/.local/state/bloody-writer    phase state and backups
├── ~/.local/share/nvim             downloaded plugins/spell data
├── ~/.codex                        credentials, sessions, CLI state
└── ~/.ssh                          generated keys and host config
```

## Why symlinks

The repository is the maintained configuration source. A `git pull` updates tracked dotfiles
without maintaining a second copied snapshot. The installer still reapplies dependency and
verification phases after an update.

Personal settings are not symlinked into Git. `~/.config/bloody-writer/settings.zsh` stores
local paths and the selected SSH key.

## Phase transaction behavior

A phase is marked complete only after its function returns successfully. This gives the
installer three useful properties:

1. A failed command cannot falsely advance the installation.
2. Restart checkpoints remain pending until the next process verifies the new WSL state.
3. Repeated execution skips completed work by default.

There is no background daemon and no automatic Windows restart.

## Update flow

```text
bloody-writer update
        │
        ├── require a clean Bloody Writer checkout
        ├── git pull --ff-only
        ├── clear dependency/config verification markers
        └── run the normal installer
```

Fast-forward-only pulls prevent an update command from manufacturing merge commits or
overwriting local edits.

## Versioning

`versions.env` pins:

- The Bloody Writer release version.
- Oh My Zsh commit.
- Codex CLI release.

`lazy-lock.json` pins Neovim plugin commits. Arch and global npm dependencies follow their
current package repositories and are recorded by name under `manifests/`. The versions observed
when this snapshot was curated are recorded in `docs/SNAPSHOT.md`; pinning rolling system
package files without maintaining a package archive would produce a false promise of
reproducibility.
