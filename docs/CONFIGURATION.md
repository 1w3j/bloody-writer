# Configuration map

## Managed targets

| Installed target | Repository source | Purpose | Platforms |
|---|---|---|---|
| `~/.zshrc` | `dotfiles/zsh/.zshrc` | Prompt, aliases, Writer/remote functions, keychain | WSL + Termux |
| `~/.tmux.conf` | `dotfiles/tmux/.tmux.conf` | Portable shell path, behavior, theme, clipboard copy | WSL + Termux |
| `~/.config/nvim` | `dotfiles/nvim/.config/nvim` | Writer Neovim and live cheat sheet | WSL + Termux |
| `~/.local/bin/tma` | `dotfiles/local-bin/.local/bin/tma` | List, attach, create, confirmed kill | WSL + Termux |
| `~/.local/bin/bw-clipboard-copy` | matching `dotfiles/local-bin` source | tmux clipboard dispatch | WSL + Termux |
| `~/.local/bin/bloody-writer` | `bin/bloody-writer` | install/update/status/doctor/remote command | WSL + Termux |
| `~/.termux/colors.properties` | `terminal/termux/colors.properties` | Android terminal palette | Termux only |

Managed files are symlinks into the Git clone so a reviewed pull becomes the maintained source.
The linker backs up any conflicting pre-existing target first.

## Private local settings

The installer creates but never tracks:

```text
~/.config/bloody-writer/settings.zsh
```

| Variable | Example purpose |
|---|---|
| `BLOODY_WRITER_DOCUMENTS` | Windows or Android Documents directory opened by `writer` |
| `BLOODY_WRITER_GITHUB_KEY` | Device-local private GitHub key path used by keychain |
| `BLOODY_WRITER_WSL_HOST` | Tailnet DNS/IP used by Termux on Android |
| `BLOODY_WRITER_WSL_USER` | Linux user on remote WSL |
| `BLOODY_WRITER_WSL_TMA` | Absolute WSL `tma` path |

See `dotfiles/zsh/settings.zsh.example` for neutral defaults. Never put real hostnames, usernames,
tokens, or key material in that template.

## Shell commands

| Command | Behavior |
|---|---|
| `writer` | Open the configured Documents directory in Neovim |
| `v`, `vim` | Open Writer Neovim |
| `tn` | Create/attach local tmux session `writer` |
| `ta`, `tma` | Open local/remote session picker |
| `wsl-writer` | From Termux on Android, SSH into WSL and open remote `tma` |

Oh My Zsh automatic updates are disabled because `versions.env` tracks a reviewed commit.

## Neovim

| Concern | Source |
|---|---|
| Theme | `lua/writer/theme.lua` |
| Plugins | `lua/writer/plugins.lua` |
| Locked plugin commits | `lazy-lock.json` |
| Platform clipboard | `lua/writer/platform.lua` |
| Live guide | `CHEATSHEET.md` |

The platform module chooses Windows interop in WSL or Termux:API on Android. `Ctrl-c`/`Ctrl-v`
map to the detected system clipboard and `Ctrl-q` preserves Visual Block.

## Codex

The WSL phase creates `~/.codex/config.toml` only when absent and installs the pinned official
Linux CLI. It never copies `auth.json`, sessions, archives, databases, installation IDs, or plugin
caches.

Termux on Android does not receive a local Codex binary. `wsl-writer` enters the supported WSL
installation through the existing private SSH/tmux workflow.

## Palette

| Role | Value |
|---|---|
| Background / soft background | `#000000` / `#120000` |
| Foreground / pure white | `#FFF1F1` / `#FFFFFF` |
| Blood / bright red | `#B00020` / `#FF334D` |
| Deep / dark selection | `#7A0014` / `#52000E` |
| Muted red / rose | `#632A2A` / `#DFA0A0` |
| Orange / blue / semantic green | `#FFB86C` / `#AFCBFF` / `#A8D5BA` |

The synchronization and publishing workflow is documented in
[`CUSTOMIZING.md`](CUSTOMIZING.md).
