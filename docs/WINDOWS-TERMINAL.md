# Windows Terminal and font

The Linux installer cannot safely rewrite every user's Windows Terminal settings. Apply this
host layer once from Windows.

## Font

Install **JetBrainsMono Nerd Font Mono** from the official Nerd Fonts distribution. The Mono
variant keeps Powerline and file icons aligned.

In Windows Terminal:

```text
Settings → Arch Linux → Appearance
Font face: JetBrainsMono Nerd Font Mono
Font size: 13 or 14
Cursor shape: Filled box
```

## Color scheme

Open:

```text
Windows Terminal → Settings → Open JSON file
```

Copy the object from [`terminal/bloody-writer.json`](../terminal/bloody-writer.json) into the
top-level `schemes` array. Then select `Bloody Writer` for the Arch Linux profile.

The ANSI green slots are intentionally red in the terminal palette. This prevents CLI selection
and success highlighting from introducing a low-contrast pastel-green background. Neovim keeps
its separate semantic green for strings, hints, and completed tasks.

## Verify

```zsh
for color in {0..15}; do
  (( color >= 7 )) && text=0 || text=15
  printf "\e[48;5;${color}m\e[38;5;${text}m %2s \e[0m " "$color"
  (( color == 7 )) && printf "\n"
done
printf "\n"
```

Powerline arrows should join cleanly, the background should be true black, and normal text
should be warm white.
