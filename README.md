# Bloody Writer

An opinionated, reproducible **Arch Linux on WSL 2** terminal workspace with a true-black,
blood-red, and warm-white visual language.

Bloody Writer recreates the maintained configuration snapshot—not private machine state. It
installs Zsh, Oh My Zsh with Agnoster, Neovim, tmux, Codex CLI, Git/GitHub tooling, language
servers, formatters, spell files, and an optional private phone-to-WSL remote workflow.

> **Theme palette:** `#000000` background · `#FFF1F1` foreground · `#B00020` blood red ·
> `#FF334D` bright red · `#7A0014` selection

## What you get

- A portable Zsh/Agnoster prompt with the Bloody Writer red path segment.
- A locked Neovim writing and coding environment with:
  - Markdown rendering, navigation, task cycling, formatting, and Zen mode.
  - English and Spanish spelling.
  - NvimTree, Telescope, Blink completion, LSP, Git signs, and a custom theme.
  - A responsive in-editor quick reference opened with `Space ?`.
- A matching tmux workspace using `Ctrl-a`, mouse support, Windows clipboard copy mode, and
  the interactive `tma` session picker.
- Codex CLI installed from OpenAI's standalone installer into the Linux user profile.
- GitHub CLI, a dedicated passphrase-protected SSH key, and keychain reuse.
- Resumable phases, automatic pre-change backups, diagnostics, update commands, and
  operational documentation.
- Optional Tailscale SSH access from Android Termux without exposing port 22 publicly.

## Quick start

### 1. Install Arch Linux on WSL

Open **PowerShell as Administrator**:

```powershell
wsl --install -d archlinux
```

If Windows asks for a reboot, reboot and run the command again. The optional
[`windows/bootstrap-wsl.ps1`](windows/bootstrap-wsl.ps1) performs the same checks and is safe
to rerun.

### 2. Clone from the first Arch shell

The first official Arch WSL shell may open as `root`:

```bash
pacman -Syu --needed git
git clone https://github.com/1w3j/bloody-writer.git
cd bloody-writer
./install.sh
```

When run as root, the installer switches into the one-time user bootstrap. It creates a normal
user, enables `wheel` sudo access, configures systemd and WSL defaults, and copies the clone
into the new user's home.

Run the displayed `wsl --terminate ...` command from PowerShell, reopen Arch, then:

```bash
cd ~/bloody-writer
./install.sh
```

The same command resumes at the first unfinished phase after every restart or interruption.

### 3. Finish interactive authentication

The installer may open these user-owned flows:

- Codex device authentication.
- GitHub browser authentication.
- An SSH-key passphrase prompt.

Passwords, tokens, private keys, Codex sessions, and authentication files are never stored in
this repository.

## Daily commands

| Command | Purpose |
|---|---|
| `./install.sh` | Install or resume unfinished phases |
| `bloody-writer status` | Show completed and pending phases |
| `bloody-writer doctor` | Diagnose the installed workspace |
| `bloody-writer update` | Fast-forward the repo and reapply changed layers |
| `bloody-writer backup` | Archive the managed configuration |
| `bloody-writer restore` | Restore the latest pre-install dotfile backup |
| `bloody-writer remote` | Opt in to private Tailscale SSH |
| `tma` | Choose and attach to a tmux session |
| `writer` | Open `~/Documents` in Writer Neovim |

## Restart and resume model

Each successful phase writes a small marker under:

```text
~/.local/state/bloody-writer/completed/
```

If WSL must restart, the current phase remains incomplete. After `wsl --terminate` and a new
Arch shell, rerunning `./install.sh` verifies the restart and continues. A failed or cancelled
phase behaves the same way; completed work is not repeated.

See [Installation and phases](docs/INSTALL.md) for options such as `--dry-run`, `--only`, and
`--skip-github`.

## Reproducibility boundary

Bloody Writer reproduces the configuration and pinned application layers that are safe to
publish. It is deliberately not a disk image:

| Tracked or pinned | Recreated locally | Never copied |
|---|---|---|
| Dotfiles and palette | Arch packages | Private SSH keys |
| Neovim lockfile | Plugin downloads | GitHub/Codex tokens |
| Oh My Zsh commit | Spell files | Shell history |
| Codex release | Git identity prompts | Caches and logs |
| Installer behavior | User paths and services | Projects and documents |

Arch is rolling release software, so repository packages are installed from the current Arch
repositories. `versions.env` pins the layers where deterministic pinning is practical.

## Documentation

- [Installation and phases](docs/INSTALL.md)
- [Workspace cheat sheet](docs/CHEATSHEET.md)
- [Configuration map](docs/CONFIGURATION.md)
- [Snapshot record](docs/SNAPSHOT.md)
- [Architecture and state model](docs/ARCHITECTURE.md)
- [Windows Terminal and font](docs/WINDOWS-TERMINAL.md)
- [Phone and remote access](docs/REMOTE-ACCESS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Maintenance and releases](docs/MAINTENANCE.md)
- [Security model](docs/SECURITY-MODEL.md)
- [Upstream sources](docs/SOURCES.md)

## Platform scope

The supported target is:

```text
Windows 11 → WSL 2 → Arch Linux → Zsh → tmux → Neovim / Codex
```

Native Linux and Termux configuration files are useful references, but the installer currently
refuses unsupported platforms rather than partially modifying them.

## License

[MIT](LICENSE)
