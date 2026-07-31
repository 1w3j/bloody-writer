# Termux on Android → Windows WSL remote sessions

The recommended mobile path is:

```text
Termux terminal on Android
        │
        │ Tailscale SSH (private tailnet)
        ▼
Arch Linux on Windows WSL 2
        │
        └── tma → selected persistent tmux session → Neovim / shell / Codex
```

This does not expose router port 22. Attaching adds the phone/tablet as another tmux client and
does not disconnect Windows Terminal.

## 1. Prepare the Windows WSL host

Finish the WSL installer and required restart, then in Arch Linux on Windows WSL:

```bash
bloody-writer remote
```

The platform-aware command:

1. Installs Tailscale from Arch's package repository.
2. Enables `tailscaled` with systemd.
3. Runs `sudo tailscale up --ssh` for an interactive tailnet login.
4. Prints the WSL tailnet DNS name/IP and Linux username needed on Android.

## 2. Prepare Termux on Android

1. Install the Tailscale Android app.
2. Sign in to the same tailnet as the WSL host.
3. In the main Termux prompt, run:

```bash
bloody-writer remote
```

Enter the WSL tailnet host/IP and WSL Linux username printed by step 1. Bloody Writer writes these
device-local values to `~/.config/bloody-writer/settings.zsh` and creates no credential in Git.

Start a new shell:

```bash
exec zsh
```

## 3. Attach daily

```bash
wsl-writer
```

The command expands to a safe explicit SSH target and the absolute remote `tma` path. In the
picker:

| Key | Result |
|---|---|
| `Enter` | Attach the selected WSL tmux session to this Termux terminal |
| `Ctrl-X` | Display a destructive-action confirmation; `y` kills that exact session |
| `Esc` | Cancel without changing any session |

If `fzf` is unavailable, the fallback menu uses `NUMBER` to attach and `k NUMBER` to request a
confirmed kill.

## What persists

tmux persists work while the **WSL virtual machine is running**. Remote availability requires:

- The Windows PC is powered on.
- Windows is awake, not sleeping or hibernating.
- WSL is running.
- Tailscale is connected on both devices.
- Tailnet SSH policy permits the user/device.

Bloody Writer does not silently change Windows power policy or create an always-on scheduled task.
Those host decisions affect energy use and security and remain owner-controlled.

## Direct command for troubleshooting

If the `wsl-writer` function is not loaded, use:

```bash
ssh -t WSL_USER@WSL_TAILNET_HOST /home/WSL_USER/.local/bin/tma
```

Then inspect the saved values:

```bash
grep 'BLOODY_WRITER_WSL_' ~/.config/bloody-writer/settings.zsh
```

Rerun `bloody-writer remote` in Termux to replace them safely.

## Security checklist

- Do not forward public TCP port 22 on the router.
- Keep Tailscale account MFA and device approval enabled.
- Review tailnet SSH access rules before adding other users.
- Revoke a lost Android device immediately.
- Keep the WSL GitHub private key passphrase-protected.
- Remember that killing a tmux session ends every process in it; `tma` confirmation is deliberate.
