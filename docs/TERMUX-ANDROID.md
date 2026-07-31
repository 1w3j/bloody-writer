# Termux on Android installation

Bloody Writer treats Termux on Android as a first-class mobile workstation, not merely an SSH
command launcher. The native Termux layer gets the same visual language, Zsh workflow, tmux,
Writer Neovim, GitHub/SSH tooling, language servers, cheat sheets, and safe update model as WSL.

## Install the Android apps safely

Use one source for the Termux family:

- F-Droid: install both **Termux** and **Termux:API** from F-Droid; or
- GitHub: install both APKs from their official GitHub release pages.

Do not mix the two sources: their app signatures differ. Avoid obsolete store builds that no
longer receive the current package ecosystem.

The **Tailscale Android app** is optional for remote WSL access but recommended for using Codex
and continuing desktop tmux sessions from the phone or tablet.

## Fresh installation

Open the main Termux prompt:

```bash
pkg update
pkg install git
git clone https://github.com/1w3j/bloody-writer.git
cd bloody-writer
./install.sh
```

Do not enter `proot-distro login archlinux` before running the script. Bloody Writer installs
`proot-distro` as an optional companion, but manages the reliable Android integration from native
Termux where `pkg`, Android storage, and Termux:API are available.

## What automatic detection changes

| Installer concern | Native Termux behavior |
|---|---|
| Privilege | Refuses root; never uses `sudo` |
| Packages | Reads `manifests/termux-packages.txt` and runs `pkg` |
| Login shell | Uses Termux's `chsh` and `$PREFIX/bin/zsh` |
| Clipboard | Neovim/tmux call Termux:API commands |
| Shared files | Requests Android permission and uses `~/storage/shared/Documents` |
| Font/colors | Installs pinned Nerd Font as `~/.termux/font.ttf` and links the palette |
| Neovim | Rebuilds plugins locally for the Android CPU; never copies WSL caches |
| Codex | Uses the official CLI in remote WSL; no unofficial Android binary |
| Remote | Saves WSL Tailscale host/user and exposes `wsl-writer` |

## Expected pauses

### Shared-storage permission

The installer runs `termux-setup-storage`. Android owns the permission dialog, so the installer
may pause. Grant the requested file access, return to Termux, and run:

```bash
cd ~/bloody-writer
./install.sh
```

### Termux:API companion

The `termux-api` package supplies command-line clients, while the separate Android app supplies
the permission bridge. If the bridge is unavailable, the installer explains which app is needed
and stops. Install it from the same source as Termux, reopen Termux, and rerun `./install.sh`.

## Documents and Android storage

The installer writes this private local setting:

```zsh
export BLOODY_WRITER_DOCUMENTS="$HOME/storage/shared/Documents"
```

It lives in `~/.config/bloody-writer/settings.zsh`, not in Git. Run `writer` to open that folder.
Android file-provider and scoped-storage behavior can vary by device; `bloody-writer doctor`
reports whether the shared-storage link exists.

## Local Termux tmux sessions

```bash
tn                 # local session named writer
tma                # list/attach local Termux sessions
tma --list
tma --kill NAME    # confirmation is mandatory
```

These are Android-local sessions. `wsl-writer` is different: it connects to the Windows WSL
machine and runs WSL's `tma`, so the selected desktop session appears in the current phone/tablet
terminal.

## Configure the remote WSL workstation

After the WSL installation has run `bloody-writer remote`, sign in to the same Tailscale account
in the Android app. Then in Termux:

```bash
bloody-writer remote
exec zsh
wsl-writer
```

The setup stores only the WSL tailnet host, Linux username, and remote `tma` path. SSH host keys,
private keys, Tailscale state, and authentication remain outside the repository.

## Optional Arch PRoot

`proot-distro` is installed for users who need a conventional Linux userspace. It is not a VM,
does not provide a separate kernel, and has different performance/security behavior. Keep the
Bloody Writer source of truth and Android integrations in main Termux. Do not copy Neovim plugin
caches between PRoot, native Termux, and WSL; run the installer/plugin sync in each managed
environment instead.

## Update and diagnose

```bash
bloody-writer status
bloody-writer doctor
bloody-writer update
```

If Android revokes a permission or Termux:API stops responding, reset the host layer and rerun it:

```bash
bloody-writer reset-phase 25-host-theme
./install.sh --only 25-host-theme
```
