# Installation and phases

## Requirements

- Windows 11 or a supported Windows 10 build.
- WSL 2 with the official `archlinux` distribution.
- Internet access during package, plugin, Codex, and authentication phases.
- Administrator rights for initial WSL installation.
- A normal Linux user with sudo access after the root bootstrap.

## Main command

```bash
./install.sh
```

The script is idempotent and resumable. It never unregisters a WSL distribution, deletes a
home directory, or copies credentials into Git.

## Phase reference

| Phase | Responsibility | May prompt | Restart |
|---|---|---:|---:|
| `00-preflight` | Validate Arch, WSL, user, repository, and sudo | sudo | No |
| `10-system` | systemd, default WSL user, interop, English/Spanish locales | Yes | If changed |
| `20-packages` | Full Arch upgrade, workstation packages, Node tools | pacman | No |
| `30-shell` | Pinned Oh My Zsh and Zsh login shell | Yes | New shell only |
| `40-dotfiles` | Back up conflicts and link the tracked configuration | No | No |
| `50-neovim` | Verified spell files and locked plugins | Network | No |
| `60-codex` | Pinned standalone Codex and optional device login | Browser | No |
| `70-github` | Git identity, GitHub login, SSH key, keychain | Browser/passphrase | No |
| `90-verify` | Commands, links, tmux, Neovim, and version checks | No | No |

## Options

```text
--yes
```

Accept phase-level confirmations. Password and browser authentication prompts still remain
interactive.

```text
--dry-run
```

Print planned changes. Nothing is installed, linked, or marked complete.

```text
--force
```

Rerun completed phases. Existing managed links are preserved; package and plugin operations
remain idempotent.

```text
--from 40-dotfiles
```

Start at a named phase.

```text
--only 90-verify
```

Run exactly one phase.

```text
--skip-github
--skip-codex-login
```

Install the tools but defer the corresponding account setup.

## Root bootstrap

The first official Arch WSL launch may be root. Running `./install.sh` as root delegates to
`scripts/bootstrap-root.sh`, which:

1. Installs the minimum bootstrap packages.
2. Creates a named normal user and asks the human to set its password.
3. Grants the `wheel` group sudo through `/etc/sudoers.d/10-wheel`.
4. Configures systemd, WSL interop, and the default user.
5. Copies the current Git clone into the new home and fixes ownership.
6. Stops before terminating WSL, so no command is cut off mid-write.

The script then prints the exact PowerShell restart and resume commands.

## Backups

Before replacing a conflicting managed target, the installer moves it to:

```text
~/.local/state/bloody-writer/backups/YYYYMMDD-HHMMSS-NNNNNNNNN/
```

The backup contains a `manifest.tsv` mapping the original paths to their preserved locations.
Backups are never automatically deleted.

Create an additional portable configuration archive with:

```bash
bloody-writer backup
```

Restore the latest automatic pre-install backup with:

```bash
bloody-writer restore
```

Restore is interactive. It removes only links pointing into the current Bloody Writer checkout,
preserves unrelated post-install files under the selected backup's `pre-restore/` directory, and
then returns the original paths from the manifest.

## Interrupted installation

Rerun:

```bash
./install.sh
```

The failing phase starts again. Inspect state with:

```bash
bloody-writer status
```

To deliberately rerun one phase:

```bash
bloody-writer reset-phase 50-neovim
./install.sh
```
