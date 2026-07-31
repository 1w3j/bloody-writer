# Snapshot record

Bloody Writer 0.1.0 was curated from the working Arch WSL environment on 2026-07-31.
This record describes the observed baseline; the installer follows current Arch repositories
for rolling packages.

## Core observed versions

| Component | Snapshot version |
|---|---|
| Arch `base-devel` | `1-2` |
| Zsh | `5.9.2-1` |
| Oh My Zsh | `7ea697fd8138550ddf7262456d412f0dcd1cbf84` |
| Neovim | `0.12.4-1` |
| tmux | `3.7_b-1` |
| Codex CLI | `0.146.0` |
| Git | `2.55.0-1` |
| GitHub CLI | `2.96.0-1` |
| OpenSSH | `10.4p1-3` |
| Node.js LTS | `24.18.0-1` |
| npm | `12.0.1-1` |
| pnpm | `11.3.0-1` |
| Python | `3.14.6-1` |
| ripgrep | `15.2.0-1` |
| fzf | `0.74.1-1` |
| fd | `10.4.2-2` |
| Marksman | `20260208-3` |
| Lua language server | `3.18.2-1` |

## Global npm tool versions

| Package | Snapshot version |
|---|---|
| `bash-language-server` | `5.6.0` |
| `prettier` | `3.9.6` |
| `pyright` | `1.1.411` |
| `typescript` | `7.0.2` |
| `typescript-language-server` | `5.3.0` |
| `vscode-langservers-extracted` | `4.10.0` |

## Configuration included

- Current custom Neovim configuration and its 17-entry `lazy-lock.json`.
- The WSL-specific clipboard layer and responsive `Space ?` guide.
- Current Bloody Writer tmux theme and `tma` session picker.
- A portable equivalent of the current Zsh/Agnoster theme and aliases.
- Windows Terminal's evolved palette, including red ANSI highlight slots.
- Safe Codex sandbox defaults and pinned standalone CLI release.
- GitHub/SSH/keychain behavior recreated without copying credentials.

## Historical decisions retained

- Plugins are rebuilt for WSL x86-64; Android/Termux plugin caches are never copied.
- LuaRocks integration is disabled while no locked plugin needs it.
- `Ctrl-c` and `Ctrl-v` use the Windows clipboard; Visual Block moved to `Ctrl-q`.
- NvimTree selection uses high-contrast white on `#52000E`.
- The quick reference becomes a centered overlay below 140 columns.
- `vim` intentionally resolves to the same Neovim writer environment.
- GitHub key passphrases are cached for the WSL lifetime, not stored.

## Intentionally excluded

Business-specific web-server/PHP packages, project repositories, private keys, GitHub tokens,
Codex authentication/state, shell history, local caches, generated dependencies, and personal
absolute paths are outside the public terminal-configuration snapshot.
