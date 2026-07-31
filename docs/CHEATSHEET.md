# Bloody Writer operations cheat sheet

The complete in-editor keyboard guide lives at
[`dotfiles/nvim/.config/nvim/CHEATSHEET.md`](../dotfiles/nvim/.config/nvim/CHEATSHEET.md)
and opens inside Neovim with `Space ?`.

## Install and maintain

| Command | Action |
|---|---|
| `./install.sh` | Install or resume |
| `./install.sh --dry-run` | Preview |
| `bloody-writer status` | Phase status |
| `bloody-writer doctor` | Environment checks |
| `bloody-writer update` | Pull and reapply |
| `bloody-writer backup` | Configuration archive |
| `bloody-writer restore` | Restore pre-install dotfiles |
| `bloody-writer reset-phase PHASE` | Reopen one phase |

## Writer loop

| Command/key | Action |
|---|---|
| `writer` | Open Documents in Neovim |
| `Space ?` | Toggle Neovim quick reference |
| `Space w` | Save |
| `Space z` | Zen writing mode |
| `Space m r` | Toggle rendered Markdown |
| `Space m f` | Format |
| `Ctrl-c`, `Ctrl-v` | Windows clipboard copy/paste |
| `Ctrl-q` | Visual Block |

## tmux

| Command/key | Action |
|---|---|
| `tn` | Create/attach `writer` |
| `tma` | Pick any session |
| `Ctrl-a c` | New window |
| `Ctrl-a \|`, `Ctrl-a -` | Split right/below |
| `Ctrl-a h/j/k/l` | Move between panes |
| `Ctrl-a d` | Detach |
| `Ctrl-a [` | Copy mode |
| `v`, then `y` | Select and copy to Windows |

## Codex and GitHub

| Command | Action |
|---|---|
| `CODEX_HOME=$HOME/.codex codex` | Start Linux Codex state explicitly |
| `codex resume` | Choose an earlier task |
| `codex doctor` | Diagnose Codex |
| `gh auth status` | Check GitHub login |
| `ssh-add -l` | List unlocked SSH keys |
| `git status` | Review working tree |
| `git diff` | Review changes |

## Remote phone

```bash
ssh -t linux-user@wsl-tailnet-name /home/linux-user/.local/bin/tma
```

This logs in, lists all tmux sessions, and attaches the selected session as another client.
