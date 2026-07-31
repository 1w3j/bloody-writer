# Windows Terminal host layer

Bloody Writer can safely add its own Windows Terminal profile, color scheme, icon, and user-level
font. It does not rewrite every user's `settings.json`, change existing profiles, or choose a new
default profile.

## Automatic phase

From Arch Linux on Windows WSL, phase `25-host-theme` invokes:

```text
windows/apply-host-theme.ps1
```

The script:

1. Reads the pinned Nerd Font version/checksum from `versions.env`.
2. Downloads JetBrainsMono Nerd Font Mono from the official Nerd Fonts repository.
3. Verifies SHA-256 before installing it for the current Windows user.
4. Writes a Windows Terminal per-user fragment under:

   ```text
   %LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\BloodyWriter\
   ```

5. Copies the public logo beside the fragment and creates the separate profile
   **Bloody Writer - Arch WSL**.

Windows Terminal must fully close and reopen to discover the new font/profile. The Linux installer
records this manual checkpoint and resumes only after the user confirms the reload.

## Why a fragment

A fragment adds a profile and scheme without taking ownership of the user's main configuration.
Existing defaults, keybindings, other distributions, and hand-edited settings remain intact.

If the automatic helper cannot run, execute it from Windows PowerShell after cloning the repo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\apply-host-theme.ps1 -DistroName archlinux
```

Then close all Windows Terminal windows and reopen **Bloody Writer - Arch WSL**.

## Visual verification

Inside the profile:

```zsh
for color in {0..15}; do
  (( color >= 7 )) && text=0 || text=15
  printf "\e[48;5;${color}m\e[38;5;${text}m %2s \e[0m " "$color"
  (( color == 7 )) && printf "\n"
done
printf "\n"
```

Powerline arrows should join cleanly, the background should be true black, normal text warm white,
and highlights red. ANSI green slots intentionally map to red; Neovim uses separate semantic
colors where appropriate.

Termux on Android does not use this Windows host file. Its equivalent lives in
[`terminal/termux/colors.properties`](../terminal/termux/colors.properties) and is installed by
the same platform-aware phase.
