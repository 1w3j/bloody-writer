# Bloody Writer workspace cheat sheet

This is the operational map: what the repository gives you, where it works, and how the pieces
connect. The full in-editor keyboard guide lives at
[`dotfiles/nvim/.config/nvim/CHEATSHEET.md`](../dotfiles/nvim/.config/nvim/CHEATSHEET.md) and
opens with `Space ?`.

## Your installed workspace at a glance

| You want to… | Bloody Writer gives you… | Start here |
|---|---|---|
| Write without UI noise | Centered Zen mode, Markdown rendering, spelling, word count | `writer`, then `Space z` |
| Navigate a project | File tree, fuzzy files/text, symbols, diagnostics | `Space e`, `Space f f`, `Space f g` |
| Code with feedback | LSP, completion, formatting, Git signs, diagnostics | `Space l i`, `Space m f` |
| Keep work alive | Persistent tmux sessions and multiple simultaneous clients | `tn` or `tma` |
| Move between phone and PC | Termux on Android connects privately to tmux in Windows WSL | `wsl-writer` |
| Recover setup state | Resumable phases, status, doctor, backups, restore | `bloody-writer status` |
| Maintain your fork | Fast-forward updates, manifests, locked plugins, tests | `bloody-writer update` |
| Recreate a project workstation | Approved WSL-only packages, guarded setup, verification, and resume | `bloody-writer install -w FILE` |

## What differs by platform

| Capability | Arch Linux on Windows WSL | Termux on Android |
|---|---|---|
| Package manager | `pacman` | `pkg` |
| System clipboard | `clip.exe` / PowerShell | Termux:API clipboard |
| Documents | Windows Documents link when available | Android shared `Documents` |
| Terminal styling | Separate Windows Terminal profile + user font | `~/.termux/colors.properties` + `font.ttf` |
| Codex | Official CLI runs locally | Runs in WSL; Termux attaches over SSH/tmux |
| Remote role | Tailscale SSH host | Tailscale Android client |
| Project workspace profiles | Supported, Arch WSL 2 only | Blocked before mutation; use the project remotely in WSL |

## Install and maintain

| Command | Action |
|---|---|
| `./install.sh --help` | Explain options, phases, platform behavior, checkpoints |
| `./install.sh` | Install or resume safely |
| `./install.sh --dry-run` | Preview without changing anything |
| `bloody-writer platform` | Print automatic platform detection |
| `bloody-writer status` | Show complete/pending phases and manual must-dos |
| `bloody-writer doctor` | Check packages, links, integrations, and authentication warnings |
| `bloody-writer update` | Repair known generated drift, pull fast-forward-only, relaunch fresh code, reapply |
| `bloody-writer backup` | Archive managed config without secrets |
| `bloody-writer restore` | Restore a preserved pre-install configuration |
| `bloody-writer reset-phase PHASE` | Reopen one phase deliberately |

## Project workspace profiles (Arch WSL 2 only)

| Command | Action |
|---|---|
| `bloody-writer workspace scan --project DIR --output FILE` | Write a deterministic candidate; never a ready-to-run approval |
| `bloody-writer workspace validate FILE` | Check schema, Git tracking, sources, platform, paths, and review state |
| `bloody-writer workspace audit FILE` | Compare the profile with the current WSL machine |
| `bloody-writer workspace apply FILE --dry-run` | Preview the project layer without mutation |
| `bloody-writer install --workspace FILE` | Complete the terminal base, then apply/resume the project layer |
| `bloody-writer workspace status` | Show active manifest digest and four workspace phases |
| `bloody-writer workspace resume --yes` | Continue the exact active profile generation |

Profiles recreate installable development capability—not `.env`, SQLite data, credentials,
private evidence, IDE state, caches, history, or machine identity. See
[`WORKSPACE-PROFILES.md`](WORKSPACE-PROFILES.md) before approving one.

## Writer loop

| Command/key | Action |
|---|---|
| `writer` | Open configured Documents in Writer Neovim |
| `Space ?` | Toggle responsive live reference |
| `Space w` | Save |
| `Space z` | Toggle distraction-free Zen mode |
| `Space m r` | Toggle rendered Markdown |
| `Space m t` | Cycle Markdown task state |
| `Space m f` | Format current buffer |
| `Space e` | Toggle file tree |
| `Space f f` / `Space f g` | Find files / live grep |
| `Ctrl-c`, `Ctrl-v` | Copy/paste with Windows or Android automatically |
| `Ctrl-q` | Visual Block mode after `Ctrl-v` becomes paste |

## tmux and `tma`

| Command/key | Action |
|---|---|
| `tn` | Create or attach the `writer` session |
| `tma` | Open the interactive session picker |
| `tma --list` | Print all sessions without attaching |
| `tma --kill NAME` | Ask once, then kill that exact session |
| `Enter` in `tma` | Attach as another client; existing clients remain connected |
| `Ctrl-X` in `tma` | Prompt, then kill selected session only |
| `Ctrl-a c` | New tmux window |
| `Ctrl-a \|`, `Ctrl-a -` | Split right / below |
| `Ctrl-a h/j/k/l` | Move between panes |
| `Ctrl-a d` | Detach and leave work running |
| `Ctrl-a [` then `v`, `y` | Select and copy through the platform clipboard |

Killing a tmux session ends every shell, editor, and process inside it. That is why every `tma`
kill path asks for confirmation.

## Termux on Android → Windows WSL

Run setup once on each side:

```bash
# Arch Linux on Windows WSL:
bloody-writer remote

# Main Termux prompt on Android:
bloody-writer remote
```

Daily from the phone or tablet:

```bash
wsl-writer
```

This SSH command opens WSL's `tma`, lists the persistent WSL tmux sessions, and attaches the
selected session to the current Termux terminal. The Windows PC must be powered on, awake, with
WSL and Tailscale available.

## Codex, GitHub, and SSH

| Command | Action |
|---|---|
| `codex` | Start the official Codex CLI locally in WSL |
| `codex resume` | Choose an earlier Codex task in WSL |
| `codex login status` | Check WSL Codex authentication |
| `wsl-writer` | From Termux, enter WSL tmux and continue Codex there |
| `gh auth status` | Check GitHub CLI authentication on the current device |
| `ssh-add -l` | List unlocked SSH public-key fingerprints |
| `git status` / `git diff` | Inspect theme changes before committing |

Private keys, tokens, Codex state, and histories are device-local and never part of the theme
repository.

## Maintain with an AI agent

| Need | Start here |
|---|---|
| Give a new agent the repository rules | Root `AGENTS.md` |
| Copy a complete first-task prompt | `docs/AI-MAINTAINERS.md` |
| Find the right code and docs for a task | Repository map and routing table in that guide |
| Update reviewed Neovim plugin pins | `scripts/update-neovim-lock.sh` |
| Hand off tested work | Verification and handoff template in the AI maintainer guide |
