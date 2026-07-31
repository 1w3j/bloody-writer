# Troubleshooting

## Installation paused or stopped

```bash
bloody-writer status
./install.sh
```

`status` prints the detected platform, phase state, and any manual checkpoint. Complete that
Windows or Android action first; rerunning resumes the unfinished phase.

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
