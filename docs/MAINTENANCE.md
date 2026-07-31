# Maintenance and releases

## Normal device update

```bash
cd ~/bloody-writer
bloody-writer update
```

The command classifies the checkout, pulls with `--ff-only`, relaunches itself from the newly
downloaded code, clears phases affected by the update, and reuses automatic WSL/Termux dispatch.
That self-relaunch lets one command understand phases introduced by the new version. Host phases
may pause again when a font, palette, or profile needs an operating-system reload.

Older releases allowed normal Neovim use to rewrite the tracked `lazy-lock.json`. When that is the
only change, update now preserves the previous bytes and a binary patch under
`~/.local/state/bloody-writer/update-recovery/`, restores the reviewed file, and continues without
an extra command. Staged changes or any unknown/authored file remain untouched; the updater lists
them and stops so the maintainer can commit or stash them deliberately.

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
| Neovim plugins | `scripts/update-neovim-lock.sh` → `lazy-lock.json` | `50-neovim`; `:checkhealth`, Writer feature exercise |

Review authoritative upstream release notes before changing a pin. Codex is local to WSL; the
Termux on Android workflow validates remote access rather than installing an Android binary.

## Package manifests

| File | Ecosystem |
|---|---|
| `manifests/arch-packages.txt` | Arch Linux on Windows WSL (`pacman`) |
| `manifests/termux-packages.txt` | Native Termux on Android (`pkg`) |
| `manifests/npm-globals.txt` | Shared global Node language/format tools |

Keep entries sorted, use platform-native package names, and document intentional capability gaps.

## AI-assisted maintenance

Start with [`AI-MAINTAINERS.md`](AI-MAINTAINERS.md). It provides the root-agent contract, reusable
task prompt, repository map, document routing, future upgrade invariants, verification, and handoff
format. Important decisions must be recorded in tracked code/tests/docs rather than left only in an
AI conversation.

## Release checks

```bash
tests/run.sh
git diff --check
git status --short
```

Also verify a WSL dry run, a real Termux permission/clipboard path, Windows Terminal reload, remote
`wsl-writer`, Neovim's `Space ?`, `tma` attach and confirmed kill, public image privacy, and matching
`CHANGELOG.md`/`versions.env` versions.
