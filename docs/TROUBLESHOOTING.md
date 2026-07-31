# Troubleshooting

## Installation stopped

Run:

```bash
bloody-writer status
./install.sh
```

The first pending phase resumes.

## systemd is not PID 1

Confirm `/etc/wsl.conf` contains `systemd=true`, then from PowerShell:

```powershell
wsl --terminate archlinux
wsl --distribution archlinux
```

Back in Arch:

```bash
ps -p 1 -o comm=
./install.sh
```

## Git asks for the key passphrase every pull

Start a new Zsh or reload it:

```zsh
source ~/.zshrc
ssh-add -l
```

The first shell after a full WSL/Windows shutdown may ask once. Keychain then reuses the same
agent across terminal tabs and tmux clients.

## `vim` is missing

Bloody Writer maps `vim` to Neovim in interactive Zsh. Start or reload Zsh:

```zsh
exec zsh
```

Scripts should invoke `nvim` explicitly.

## Neovim plugin failure

```bash
bloody-writer reset-phase 50-neovim
./install.sh --only 50-neovim
```

Then inside Neovim:

```vim
:Lazy
:checkhealth
:messages
```

Do not copy `.local/share/nvim/lazy`, `.local/state/nvim`, or `.cache/nvim` from Android or
another CPU architecture.

## LuaRocks warning

The current plugin graph needs no LuaRocks packages. `init.lua` deliberately configures:

```lua
rocks = { enabled = false }
```

If a future plugin documents a LuaRocks dependency, remove that setting as part of the reviewed
plugin update.

## Clipboard does not work

Outside Neovim:

```bash
printf 'clipboard test' | clip.exe
powershell.exe -NoLogo -NoProfile -Command 'Get-Clipboard'
```

Inside Neovim, `Ctrl-c` copies, `Ctrl-v` pastes, and `Ctrl-q` preserves Visual Block.

## tmux colors or icons are wrong

Check:

```bash
echo "$TERM"
tmux show -g default-terminal
```

Use JetBrainsMono Nerd Font Mono in Windows Terminal. Reload tmux with `Ctrl-a r`; existing
servers may need to be restarted after major terminal capability changes.

## `tma` says no sessions exist

That is normal on a fresh server. Enter a new name or accept `main`. Later:

```bash
tma
```

will show every session.

## Remote connection fails

```bash
systemctl status tailscaled
tailscale status
tailscale ip -4
```

Confirm Android Tailscale is connected to the same tailnet and the Windows host is awake.
