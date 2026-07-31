# Remote access from Android Termux

Bloody Writer uses Tailscale SSH for the optional remote path. This avoids router port
forwarding and does not expose the WSL SSH service to the public internet.

## WSL side

After the main installer and its WSL restart are complete:

```bash
bloody-writer remote
```

This installs Tailscale from Arch's package repository, enables `tailscaled`, and runs:

```bash
sudo tailscale up --ssh
```

Complete the displayed tailnet authentication.

## Android side

1. Install the official Tailscale Android app.
2. Sign in to the same tailnet.
3. In Termux:

```bash
pkg install openssh
ssh -t your-linux-user@your-wsl-tailnet-name /home/your-linux-user/.local/bin/tma
```

`tma` displays each tmux session, its window count, attachment state, and creation time. Choosing
an already attached session adds the phone as another tmux client; it does not disconnect the
local terminal. The full remote path is intentional: SSH commands run in a non-interactive
shell, which may not load the `~/.zshrc` entry that adds `~/.local/bin` to `PATH`.

Add a short Termux alias:

```zsh
alias wsl-writer='ssh -t your-linux-user@your-wsl-tailnet-name /home/your-linux-user/.local/bin/tma'
```

## Availability limits

tmux persists processes only while the WSL virtual machine exists. Remote access therefore
requires:

- The Windows PC to be powered on.
- Windows not to be sleeping or hibernating.
- WSL to be running.
- Tailscale to be connected on both devices.

Windows may stop an idle WSL instance. For unattended availability, use an owner-reviewed
Windows startup task and power policy appropriate for the device. Bloody Writer does not change
host power settings automatically.

## Security

- Do not open or forward TCP port 22 on the home router.
- Keep Tailscale device approval and account MFA enabled.
- Revoke a lost phone from the tailnet immediately.
- Do not disable Tailscale key expiry unless the availability tradeoff is intentional.
- Review tailnet SSH access rules before adding other users.
