# Troubleshooting

## `zsh: command not found: bloody-writer`

Before the base dotfile phase has completed, run the repository entrypoint directly:

```bash
cd ~/bloody-writer
./install.sh
```

Phase `40-dotfiles` links the command into `~/.local/bin` and installs the managed Zsh
configuration that places that directory first in `PATH`. After a successful installation, start
a fresh shell with `exec zsh` (or fully reopen Termux on Android). Verify with:

```zsh
command -v bloody-writer
bloody-writer status
```

The first command should print `~/.local/bin/bloody-writer`. Project workspace profiles do not
edit `~/.zshrc`; apply them only after the base installation is complete.

## Installation paused or stopped

```bash
bloody-writer status
./install.sh
```

`status` prints the detected platform, phase state, and any manual checkpoint. Complete that
Windows or Android action first; rerunning resumes the unfinished phase.

## Workspace profile is rejected

```bash
bloody-writer workspace validate /path/to/bloody-writer.workspace.json
git -C /path/to/project status --short
```

The profile must be approved, tracked in the same Git repository as every referenced source, a
regular file (not a symlink), schema version 1, sorted/unique, and free of unknown keys or unsafe
paths. Generated scanner output is deliberately `candidate`; review and commit it before owner
approval changes that field. Workspace profiles never run in Termux on Android, root, WSL 1,
non-Arch WSL, or another Linux distribution.

## Workspace setup stopped after packages or system files

```bash
bloody-writer workspace status
bloody-writer workspace audit /path/to/bloody-writer.workspace.json
bloody-writer workspace resume --yes
```

Failed phases do not receive completion markers. If `.env` exists, confirm it explicitly uses
`APP_ENV=local`, `DB_CONNECTION=sqlite`, and a loopback `APP_URL`; the installer never sources the
file. Existing system fragments and SQLite data are preserved under the active manifest's private
workspace backup tree before replacement/migrations.

If the profile changed, `status` shows a different current digest. Run `validate` and `apply`
again to review/trust the new generation instead of editing local state.

## Wrong platform / running inside PRoot

Run:

```bash
bloody-writer platform
```

Supported results are `Arch Linux on Windows WSL 2` and `Termux on Android`. On Android, run the
installer from the main Termux prompt where `$PREFIX/bin/pkg` exists, not inside
`proot-distro login archlinux`.

## WSL systemd is not PID 1

From Windows PowerShell:

```powershell
wsl --terminate archlinux
wsl --distribution archlinux
```

Back in Arch WSL:

```bash
ps -p 1 -o comm=
cd ~/bloody-writer && ./install.sh
```

## Windows Terminal profile/font is missing

Close **every** Windows Terminal window, reopen it, and choose **Bloody Writer - Arch WSL**. If
needed:

```bash
bloody-writer reset-phase 25-host-theme
./install.sh --only 25-host-theme
```

See [`WINDOWS-TERMINAL.md`](WINDOWS-TERMINAL.md) for the fragment path and manual command.

## Termux shared Documents is missing

```bash
termux-setup-storage
ls -ld ~/storage/shared ~/storage/shared/Documents
```

Grant Android file access, then reset/rerun phase 25. Some Android versions expose a settings
screen instead of an inline dialog; return to Termux afterward.

## Agnoster shows `u0_a…@localhost`

Update the repository and reapply the shell/dotfile phases:

```bash
cd ~/bloody-writer
bloody-writer update
```

Bloody Writer sets Agnoster's local-user baseline from Zsh's authoritative `$USERNAME` parameter,
which matches Android's generated Termux account. After a successful update, fully close the
Termux app and reopen it. Agnoster intentionally may still show context during an SSH login.

## Update reports local checkout changes

Run the update again normally:

```bash
cd ~/bloody-writer
bloody-writer update
```

If an older Bloody Writer release let Neovim rewrite only the tracked `lazy-lock.json`, the current
updater preserves the previous file and patch under
`~/.local/state/bloody-writer/update-recovery/`, restores the reviewed version, and continues.
Normal Neovim sessions now write to a device-local lock instead, so the same drift should not
return.

For any staged, unknown, deleted, renamed, or authored change, update prints the exact Git status
and stops without pulling. Review with `git diff`; commit work intended for your fork or stash it
deliberately. Do not use a broad reset or `git clean` when you do not recognize the files.

## Termux clipboard does not work

Confirm the Termux:API Android app came from the same source as Termux, then:

```bash
printf 'clipboard test' | termux-clipboard-set
termux-clipboard-get
bloody-writer doctor
```

If the command times out or Android reports a signature/permission issue, reinstall both Termux
apps from one source and rerun `25-host-theme`.

## WSL clipboard does not work

```bash
printf 'clipboard test' | clip.exe
powershell.exe -NoLogo -NoProfile -Command 'Get-Clipboard'
```

Inside Neovim, `Ctrl-c` copies, `Ctrl-v` pastes, and `Ctrl-q` preserves Visual Block on both
platforms.

## Git key passphrase repeats

```zsh
exec zsh
ssh-add -l
```

The first shell after a complete WSL/Windows or Termux process restart may ask once. Keychain
reuses the agent without storing the passphrase.

## Neovim plugin failure

```bash
bloody-writer reset-phase 50-neovim
./install.sh --only 50-neovim
```

Then run `:Lazy`, `:checkhealth`, and `:messages`. Never copy `.local/share/nvim/lazy`, Neovim
state, or native plugin caches between Android and WSL architectures.

## `tma` picker or kill behavior

```bash
tma --help
tma --list
tma --kill SESSION
```

`Ctrl-X` in fzf and `k NUMBER` in the fallback menu both request confirmation. If a session
disappears between listing and selection, rerun `tma`; exact-target validation refuses a different
similarly named session.

## Termux cannot reach WSL

On Windows WSL:

```bash
systemctl status tailscaled
tailscale status
tailscale ip -4
tmux list-sessions
```

On Termux on Android, confirm the Tailscale Android app is connected, rerun
`bloody-writer remote`, and test the explicit SSH command in [`REMOTE-ACCESS.md`](REMOTE-ACCESS.md).
The Windows PC must be powered on, awake, and running WSL.

## `vim` is missing

Bloody Writer aliases `vim` to Neovim in interactive Zsh:

```zsh
exec zsh
```

Scripts should invoke `nvim` explicitly.
