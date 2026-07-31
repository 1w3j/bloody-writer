# Installation, phases, and resume checkpoints

Bloody Writer uses one entry point on both supported platforms:

```bash
./install.sh
```

It detects **Arch Linux on Windows WSL 2** or the **main Termux environment on Android**. No
platform flag is required. Unsupported environments stop during preflight before system changes.

## Before running

| Windows WSL | Termux on Android |
|---|---|
| Windows 11, WSL 2, official `archlinux` distribution | Current Termux app from F-Droid or official GitHub releases |
| Administrator rights only for initial WSL installation | No Android root and no `sudo` |
| Normal Arch user with `sudo` after root bootstrap | Run from main Termux prompt, not an Arch PRoot shell |
| Internet access and Windows interop | Matching-source Termux:API Android companion app |

Review `scripts/phases/` before installing on a sensitive device. Account logins, passwords, and
SSH-key passphrases remain interactive even with `--yes`.

## Friendly help

```bash
./install.sh --help
tma --help
```

The installer help explains its phases, examples, platform behavior, and every skip option. The
`tma` help explains local and SSH attach behavior plus safe session killing.

## Phase reference

| Phase | Windows WSL behavior | Termux on Android behavior | Can pause? |
|---|---|---|---:|
| `00-preflight` | Verify WSL 2, Arch, user, repo, `sudo` | Verify native Termux prefix, app user, `pkg` | No |
| `10-system` | Configure systemd/default user/interop/locales | Leave Android-owned init and system files alone | **WSL restart** |
| `20-packages` | Upgrade/install tracked Arch and npm packages | Upgrade/install tracked Termux and npm packages; install Black | Package prompts/errors only |
| `25-host-theme` | Install verified Nerd Font and safe Windows Terminal fragment | Request Android storage, verify Termux:API, install font/colors | **Host action** |
| `30-shell` | Install pinned Oh My Zsh and set `/usr/bin/zsh` | Install same snapshot and set Termux Zsh | No |
| `40-dotfiles` | Back up/link shell, tmux, Neovim, commands, Windows Documents | Link same portable files and Android clipboard helper | No |
| `50-neovim` | Verify spell assets and sync locked plugins | Same, rebuilt for Android architecture | Network only |
| `60-codex` | Install pinned official Linux Codex CLI and optionally log in | Configure the supported remote-WSL model; never install unofficial Android builds | Login on WSL |
| `70-github` | Git identity, GitHub login, dedicated SSH key, keychain | Same user-owned setup inside Termux | Browser/passphrase |
| `90-verify` | Commands, links, tmux, Neovim, Codex | Commands, links, Termux font/storage/clipboard, tmux, Neovim | No |

## Options

| Option | Meaning |
|---|---|
| `--yes` | Accept safe phase confirmations; never answers passwords or login flows |
| `--dry-run` | Print intended commands without changing files, packages, or phase state |
| `--force` | Rerun completed phases |
| `--from PHASE` | Begin at a named phase while preserving earlier completion state |
| `--only PHASE` | Run exactly one named phase |
| `--skip-host-theme` | Leave Windows Terminal or Termux font/color work pending |
| `--skip-github` | Leave phase 70 pending without creating identity or keys |
| `--skip-codex` | Leave the Codex phase pending |
| `--skip-codex-login` | Install Codex in WSL without launching device authentication |

Examples:

```bash
./install.sh --dry-run
./install.sh --yes --skip-github
./install.sh --only 90-verify
./install.sh --from 40-dotfiles
```

## Pause and resume contract

Successful phases create a marker under:

```text
~/.local/state/bloody-writer/completed/
```

Manual checkpoints record their instruction under:

```text
~/.local/state/bloody-writer/manual/
```

A phase that needs outside action returns without a completion marker. The installer prints exact
steps and stops; it never pretends the whole setup is complete.

Typical resume loop:

```bash
bloody-writer status   # shows the platform, pending phase, and checkpoint text
# complete the displayed Windows or Android action
cd ~/bloody-writer
./install.sh
```

On rerun, the pending phase verifies the inconvenience was resolved. If it was not, the installer
pauses again without repeating previous work.

### WSL systemd checkpoint

When `/etc/wsl.conf` changes, run the printed commands from Windows PowerShell:

```powershell
wsl --terminate archlinux
wsl --distribution archlinux
```

Then return to `~/bloody-writer` and rerun `./install.sh`.

### Windows Terminal checkpoint

The Linux installer invokes `windows/apply-host-theme.ps1`, but Windows Terminal must reload its
font and fragment:

1. Close every Windows Terminal window.
2. Open Windows Terminal again.
3. Select **Bloody Writer - Arch WSL**.
4. Run `cd ~/bloody-writer && ./install.sh`.

### Android checkpoints

Android may display a shared-storage permission prompt. Grant it, return to Termux, and rerun the
installer. If Termux:API is absent, install its Android companion from the same source as Termux,
then rerun. The installer verifies both conditions before advancing.

## Fresh Arch WSL root bootstrap

The official first Arch shell may be root. Running `./install.sh` there delegates to
`scripts/bootstrap-root.sh`, which:

1. Installs only the bootstrap packages.
2. Creates a named normal user and asks the human for its password.
3. Grants password-protected wheel `sudo` through `/etc/sudoers.d/10-wheel`.
4. Configures systemd, WSL interop, and the default user.
5. Preserves/copies the Git clone into the normal user's home.
6. Stops before WSL termination and prints the exact resume commands.

The Termux installer rejects root; Android root is never needed.

## Backups and recovery

Before replacing a conflicting target, the installer moves it to a timestamped directory:

```text
~/.local/state/bloody-writer/backups/YYYYMMDD-HHMMSS-NNNNNNNNN/
```

The `manifest.tsv` inside records each original and saved path. Backups are never automatically
deleted.

```bash
bloody-writer backup              # make a portable managed-config archive
bloody-writer restore             # restore latest unused pre-install backup
bloody-writer reset-phase 50-neovim
./install.sh --only 50-neovim
```

Restore only accepts installer backup directories under the state root. It preserves unrelated
post-install files before putting the originals back.
