# Maintenance and releases

## Normal device update

```bash
cd ~/bloody-writer
bloody-writer update
```

The command refuses a dirty checkout, pulls with `--ff-only`, clears the phases affected by a
theme/dependency update, and reuses automatic WSL/Termux dispatch. Host phases may pause again when
a new font, palette, or profile needs an operating-system reload.

## Full customization workflow

Use [`CUSTOMIZING.md`](CUSTOMIZING.md) for the visual file map, files never to touch, private local
settings, real palette/alias/package/plugin examples, screenshot hygiene, fork setup, Git commands,
and release checklist.

## Upgrade reviewed pins

| Layer | Pin | Reset/verify |
|---|---|---|
| Oh My Zsh | `OH_MY_ZSH_COMMIT` | `30-shell`; Zsh syntax/startup/prompt |
| Codex | `CODEX_VERSION` | `60-codex`; WSL version/login/doctor |
| Nerd Font | `NERD_FONT_VERSION`, `NERD_FONT_SHA256` | `25-host-theme`; both Windows and Termux rendering |
| Neovim plugins | `lazy-lock.json` | `50-neovim`; `:checkhealth`, Writer feature exercise |

Review authoritative upstream release notes before changing a pin. Codex is local to WSL; the
Termux on Android workflow validates remote access rather than installing an Android binary.

## Package manifests

| File | Ecosystem |
|---|---|
| `manifests/arch-packages.txt` | Arch Linux on Windows WSL (`pacman`) |
| `manifests/termux-packages.txt` | Native Termux on Android (`pkg`) |
| `manifests/npm-globals.txt` | Shared global Node language/format tools |

Keep entries sorted, use platform-native package names, and document intentional capability gaps.

## Release checks

```bash
tests/run.sh
git diff --check
git status --short
```

Also verify a WSL dry run, a real Termux permission/clipboard path, Windows Terminal reload, remote
`wsl-writer`, Neovim's `Space ?`, `tma` attach and confirmed kill, public image privacy, and matching
`CHANGELOG.md`/`versions.env` versions.
