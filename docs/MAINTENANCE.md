# Maintenance and releases

## Normal update

```bash
cd ~/bloody-writer
bloody-writer update
```

The command refuses a dirty checkout, pulls with `--ff-only`, and reapplies dependency,
dotfile, Neovim, Codex, and verification phases.

## Change the theme

Keep the palette synchronized across:

- `terminal/bloody-writer.json`
- `dotfiles/nvim/.config/nvim/lua/writer/theme.lua`
- `dotfiles/tmux/.tmux.conf`
- `dotfiles/zsh/.zshrc`
- palette tables and screenshots in documentation

Semantic colors inside Neovim may differ from the ANSI terminal slots when readability requires
it. Document intentional divergence.

## Upgrade Neovim plugins

1. Run `:Lazy update`.
2. Review `lazy-lock.json`.
3. Run `:checkhealth`.
4. Exercise Markdown, NvimTree, Telescope, completion, LSP, and `Space ?`.
5. Run `tests/run.sh`.
6. Update the changelog.

Do not commit downloaded plugin directories.

## Change workstation packages

Edit `manifests/arch-packages.txt` or `manifests/npm-globals.txt`, update the observed baseline
in `docs/SNAPSHOT.md`, reset phase `20-packages`, and run the full tests. Keep project-specific
runtime stacks out of this terminal configuration.

## Upgrade Oh My Zsh

Update `OH_MY_ZSH_COMMIT` in `versions.env`, reset phase `30-shell`, and verify the Agnoster
`prompt_dir` override and shell startup:

```bash
zsh -n dotfiles/zsh/.zshrc
time zsh -i -c exit
```

## Upgrade Codex

Update `CODEX_VERSION` in `versions.env` after reviewing the official release. Reset phase
`60-codex`, verify `codex --version`, `codex login status`, and `codex doctor`. Never add
Codex auth or state files to Git.

## Release checklist

```bash
tests/run.sh
git diff --check
git status --short
```

Also verify:

- Fresh temporary-home linker test passes.
- Secret scan passes.
- Every shell file passes ShellCheck.
- JSON files parse.
- Documentation describes new commands and phases.
- `CHANGELOG.md` and `versions.env` agree.
