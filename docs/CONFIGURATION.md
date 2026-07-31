# Configuration map

## Managed files

| Installed target | Repository source | Purpose |
|---|---|---|
| `~/.zshrc` | `dotfiles/zsh/.zshrc` | Shell, prompt, aliases, keychain |
| `~/.tmux.conf` | `dotfiles/tmux/.tmux.conf` | tmux behavior and theme |
| `~/.config/nvim` | `dotfiles/nvim/.config/nvim` | Writer Neovim |
| `~/.local/bin/tma` | `dotfiles/local-bin/.local/bin/tma` | tmux session picker |
| `~/.local/bin/bloody-writer` | `bin/bloody-writer` | installer and maintenance command |

## Personal settings

Edit:

```text
~/.config/bloody-writer/settings.zsh
```

Supported values:

```zsh
export BLOODY_WRITER_DOCUMENTS="$HOME/Documents"
export BLOODY_WRITER_GITHUB_KEY="$HOME/.ssh/id_ed25519_github_example"
```

This file is mode `0600` and is never stored in the Git checkout.

## Zsh commands

| Command | Behavior |
|---|---|
| `writer` | Open the configured Documents directory in Neovim |
| `v`, `vim` | Open Neovim normally |
| `tn` | Create or attach the `writer` tmux session |
| `ta`, `tma` | Choose any tmux session |
| `ll`, `la` | Detailed or hidden-aware directory listing |

Oh My Zsh updates are disabled inside Zsh because the installer tracks a reviewed commit.
Change `OH_MY_ZSH_COMMIT` and re-run phase `30-shell` when intentionally upgrading.

## Neovim

The custom theme is defined in:

```text
dotfiles/nvim/.config/nvim/lua/writer/theme.lua
```

The plugin graph is defined by `plugins.lua` and locked by `lazy-lock.json`. LuaRocks support
is disabled because the current plugin graph has no LuaRocks dependency.

The live quick reference is:

```text
dotfiles/nvim/.config/nvim/CHEATSHEET.md
```

Open it with `Space ?`.

## Codex

The installer creates `~/.codex/config.toml` only when none exists. It never overwrites an
existing Codex configuration and never copies:

- `auth.json`
- sessions or archives
- SQLite state
- installation IDs
- plugin caches
- machine-specific Desktop paths

The portable baseline uses on-request approval, workspace-write sandboxing, network access
inside that sandbox, and OpenAI's official developer-documentation MCP endpoint. Adjust it
according to the sensitivity of each project.

## Theme palette

| Role | Value |
|---|---|
| Background | `#000000` |
| Soft background | `#120000` |
| Foreground | `#FFF1F1` |
| Pure white | `#FFFFFF` |
| Blood red | `#B00020` |
| Deep selection | `#7A0014` |
| Dark selection | `#52000E` |
| Bright red | `#FF334D` |
| Muted red | `#632A2A` |
| Rose | `#DFA0A0` |
| Orange | `#FFB86C` |
| Blue | `#AFCBFF` |
| Semantic green | `#A8D5BA` |
