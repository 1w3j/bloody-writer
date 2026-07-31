# Customizing and publishing your Bloody Writer theme

Treat your fork as the configuration source of truth. Make a small reviewed change, test it,
commit it, push it, and let each WSL or Termux device pull and reapply the appropriate phase.

> [!CAUTION]
> Never publish private SSH keys, tokens, Codex state, shell history, personal documents, local
> caches, or absolute home paths. Run `tests/security-scan.sh` before every push.

## File map: touch vs do not touch

| Goal | Files to change | Reapply | Never add |
|---|---|---|---|
| Terminal palette | `terminal/bloody-writer.json`, `terminal/termux/colors.properties`, `windows/apply-host-theme.ps1` | `25-host-theme` | Windows Terminal `settings.json` |
| Zsh prompt/aliases | `dotfiles/zsh/.zshrc`, `settings.zsh.example` for documented optional variables | `30-shell`, `40-dotfiles` | Your real `~/.config/bloody-writer/settings.zsh` |
| tmux theme/keys | `dotfiles/tmux/.tmux.conf`, `dotfiles/local-bin/.local/bin/tma` | `40-dotfiles`, restart/reload tmux | tmux server state or captured command output with secrets |
| Neovim theme | `lua/writer/theme.lua` | `40-dotfiles`, `90-verify` | `~/.local/share/nvim`, `~/.cache/nvim` |
| Neovim plugins | `lua/writer/plugins.lua`, generated `lazy-lock.json` | `50-neovim` | Downloaded plugin directories |
| WSL packages | `manifests/arch-packages.txt` | `20-packages` | Pacman cache/database |
| Termux packages | `manifests/termux-packages.txt` | `20-packages` | Termux app data or APKs |
| npm tools | `manifests/npm-globals.txt` | `20-packages` | `node_modules` |
| Version pins | `versions.env` plus changelog/snapshot | Relevant phase | Credentials from the upgraded tool |
| Logo/screenshots | `assets/brand/`, `assets/screenshots/`, README references | None | Personal names, hostnames, project paths, tokens |
| User-facing behavior | Script/config + `docs/CHEATSHEET.md` + detailed guide | Relevant phase | Undocumented flags or silent destructive behavior |

## Keep personal values out of the fork

Edit the installed local file—not the tracked template—for device-specific paths and targets:

```zsh
nvim ~/.config/bloody-writer/settings.zsh
```

Example private local settings:

```zsh
export BLOODY_WRITER_DOCUMENTS="$HOME/storage/shared/Documents"
export BLOODY_WRITER_WSL_HOST="my-workstation.example-tailnet.ts.net"
export BLOODY_WRITER_WSL_USER="writer"
export BLOODY_WRITER_GITHUB_KEY="$HOME/.ssh/id_ed25519_github_example"
```

Do not copy that file into `dotfiles/`; the example template documents variable names without
real values.

## Example 1: change the accent red

Suppose your new primary red is `#D1123A`.

1. Search every current palette occurrence:

   ```bash
   rg '#B00020|#FF334D' terminal dotfiles windows docs README.md
   ```

2. Update intentional theme roles in:
   - `terminal/bloody-writer.json`
   - `terminal/termux/colors.properties`
   - `dotfiles/tmux/.tmux.conf`
   - `dotfiles/nvim/.config/nvim/lua/writer/theme.lua`
   - the Agnoster `prompt_dir` color in `dotfiles/zsh/.zshrc` when ANSI behavior changes
   - `windows/apply-host-theme.ps1`
3. Update palette tables and new screenshots.
4. Run tests and preview the changed host layer:

   ```bash
   tests/run.sh
   ./install.sh --dry-run --only 25-host-theme
   ```

5. On a real test device:

   ```bash
   bloody-writer reset-phase 25-host-theme
   ./install.sh --only 25-host-theme
   ```

Semantic Neovim green may remain green; terminal ANSI slots are a separate design decision.

## Example 2: add a portable Zsh alias

Add aliases only when the underlying command works on both WSL and Termux, or guard by platform:

```zsh
alias notes='writer'

if [[ $PREFIX == */com.termux/files/usr ]]; then
  alias android-home='cd "$HOME/storage/shared"'
fi
```

Then verify and reapply:

```bash
zsh -n dotfiles/zsh/.zshrc
bloody-writer reset-phase 40-dotfiles
./install.sh --only 40-dotfiles
exec zsh
```

Document repeated commands in `docs/CHEATSHEET.md`.

## Example 3: add a package correctly

Keep each manifest sorted and use each ecosystem's real package name:

```text
manifests/arch-packages.txt     # e.g. github-cli
manifests/termux-packages.txt   # e.g. gh
manifests/npm-globals.txt       # shared global Node tools
```

If the capability is required on both platforms, add an equivalent to both OS manifests. If it
is platform-only, document the difference. Then:

```bash
LC_ALL=C sort -u manifests/termux-packages.txt
tests/run.sh
bloody-writer reset-phase 20-packages
./install.sh --only 20-packages
```

Do not replace the manifest file with generated package-manager output; comments and reviewed
scope are intentional.

## Example 4: update Neovim plugins

Inside the managed Neovim:

```vim
:Lazy update
:checkhealth
```

Review only `lazy-lock.json` and intended plugin declarations:

```bash
git diff -- dotfiles/nvim/.config/nvim/lazy-lock.json \
  dotfiles/nvim/.config/nvim/lua/writer/plugins.lua
tests/run.sh
```

Exercise Markdown rendering, file tree, Telescope, completion, LSP, formatting, spelling, and
`Space ?`. Never commit `.local/share/nvim/lazy` or cross-copy native plugin binaries between
Android ARM and WSL x86-64.

## Example 5: update public screenshots and logo

Use generic content and inspect every visible terminal line. Avoid usernames, machine names,
private repository names, SSH fingerprints, tokens, internal paths, and notification overlays.

Expected paths:

```text
assets/brand/bloody-writer-logo.png
assets/screenshots/wsl-hero.png
assets/screenshots/wsl-cheatsheet.png
assets/screenshots/tmux-session-picker.png
```

Keep README `alt` text useful. Compress images without changing legibility. The public security
scan checks known personal paths, but human visual inspection remains mandatory.

## Test, commit, and upload to your fork

First point the clone at your own public fork if needed:

```bash
git remote -v
git remote set-url origin git@github.com:YOUR_GITHUB_USER/bloody-writer.git
```

Review and test:

```bash
git status --short
git diff --check
tests/run.sh
git diff
```

Commit only intended files:

```bash
git add README.md assets docs dotfiles manifests terminal windows scripts versions.env CHANGELOG.md
git status --short
git commit -m "feat: evolve the bloody writer theme"
git push origin HEAD
```

On another installed device:

```bash
cd ~/bloody-writer
bloody-writer update
```

The update refuses local uncommitted changes. Commit them to your fork or intentionally stash
them first; Bloody Writer will not overwrite a dirty source checkout.

## Release checklist

| Check | Why it matters |
|---|---|
| Version in `versions.env` matches `CHANGELOG.md` | Users can identify the snapshot |
| `tests/run.sh` passes | Syntax, manifests, links, resume, `tma`, assets, and security are checked |
| WSL dry run reviewed | Privileged/system behavior remains explicit |
| Termux install tested | Android permissions, clipboard, package names, and font work |
| `bloody-writer doctor` reviewed on each platform | Integration warnings are visible |
| README screenshots inspected by a human | Image pixels can leak what text scans cannot see |
| No authentication/state files staged | Public release remains credential-free |

Update `docs/SNAPSHOT.md` when observed versions or supported platform behavior changes, and add a
user-facing changelog entry before publishing.
