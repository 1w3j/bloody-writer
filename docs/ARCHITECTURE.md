# Architecture and state model

## Platform dispatch

```text
./install.sh
    │
    └── bin/bloody-writer
            │
            ├── detect WSL 2 + Arch ────── pacman / systemd / Windows host / local Codex
            │
            ├── detect native Termux ───── pkg / Android storage+API / remote WSL Codex
            │
            └── anything else ──────────── stop before mutation
```

Platform checks live in `scripts/lib/common.sh`; per-phase branches stay close to the operation
they change. One ordered phase list and one state format are shared across both devices.

## Layer map

```text
Windows host                                   Android host
├── Windows Terminal fragment + user font      ├── Termux app + API companion
├── WSL 2 / Arch                               ├── Termux font/colors/storage
│   ├── pacman workstation                     ├── pkg workstation
│   ├── official Linux Codex                   ├── local tmux / Neovim / Git / SSH
│   └── Tailscale SSH host ◄───────────────────┤ Tailscale client + wsl-writer
│                                              └── optional proot-distro
└──────────────────── shared Git source ────────────────────────┘
                         ~/bloody-writer
```

## Installed state

| Path | Ownership | Meaning |
|---|---|---|
| `~/bloody-writer` | Git-tracked | Public source of truth |
| `~/.zshrc`, `~/.tmux.conf`, `~/.config/nvim` | Managed symlinks | Active portable configuration |
| `~/.config/bloody-writer` | Private/device-local | Paths, selected key, remote host/user |
| `~/.local/state/bloody-writer/completed` | Installer state | Successful phase markers |
| `~/.local/state/bloody-writer/manual` | Installer state | Pending host-owned instructions |
| `~/.local/state/bloody-writer/backups` | Recovery | Conflicting originals and archives |
| `~/.local/share/nvim` | Recreated cache/data | Architecture-specific plugins and spell assets |
| `~/.codex` | WSL private state | Config, credentials, sessions, databases |
| `~/.ssh` | Device private state | Generated keys and SSH configuration |

## Why symlinks

A fast-forward pull updates the reviewed public configuration without maintaining a second copied
snapshot. Private settings are regular untracked files, and generated/plugin state is rebuilt on
each architecture.

## Phase transaction behavior

A phase is marked complete only after returning success:

1. A failed command cannot advance state.
2. A WSL restart or host-app action leaves its phase pending.
3. The checkpoint explains the external action in `status`.
4. Rerunning verifies the condition and skips every complete phase.
5. `reset-phase` deliberately removes one marker; `--force` deliberately ignores markers.

There is no background installer daemon and no automatic Windows/Android restart.

## Update flow

```text
bloody-writer update
        │
        ├── reject a dirty source checkout
        ├── git pull --ff-only
        ├── clear affected package/theme/config/verification markers
        └── invoke the same platform-aware installer
```

## Version boundaries

`versions.env` pins the Bloody Writer version, Oh My Zsh commit, Codex release, and Nerd Font
release/checksum. `lazy-lock.json` pins Neovim plugins. Arch, Termux, and npm package manifests
track names while their rolling repositories supply current versions. `docs/SNAPSHOT.md` records
observed versions; the project does not pretend to own a historical package archive.
