# Bloody Writer agent instructions

## Purpose and scope

Bloody Writer is a public, reproducible Arch Linux on WSL 2 terminal configuration. Preserve
the true-black, blood-red, and warm-white design while keeping installation safe, resumable,
portable, and understandable to a fresh WSL user.

The current tracked configuration, `versions.env`, accepted documentation, and tests are the
repository source of truth. Old chat transcripts and screenshots are historical context only.

## Security rules

- Never commit private SSH keys, passwords, passphrases, API tokens, OAuth credentials, Codex
  authentication or session state, GitHub CLI `hosts.yml`, shell history, private repositories,
  documents, caches, logs, installation IDs, or personal absolute paths.
- Public SSH keys and Git identity still require an explicit, documented reason before being
  committed. The default is to generate or prompt locally instead.
- Keep privileged actions narrow and visible. Never add passwordless sudo.
- Never automate WSL unregister, home-directory deletion, public SSH port exposure, router
  forwarding, host power-policy changes, or secret migration.
- Downloads must use authoritative sources. Pin commits/releases where practical and verify
  static assets with checksums.

## Installer rules

- Supported install target is official Arch Linux under WSL 2.
- Every phase must be idempotent and must mark completion only after successful verification.
- Any phase that needs WSL termination must persist state, stop cleanly, print exact PowerShell
  commands, and resume when `./install.sh` is rerun.
- Back up an existing user file before replacing it or creating a managed symlink.
- Validate destructive or move targets are inside the intended home directory.
- Do not silently overwrite existing Codex, SSH, GitHub, or personal settings.
- Account authentication and key passphrases remain interactive and user-owned.
- `bloody-writer update` must preserve fast-forward-only Git behavior and reject dirty checkouts.

## Configuration rules

- Keep personal values in `~/.config/bloody-writer/settings.zsh`, never in tracked dotfiles.
- Keep Neovim plugin commits in `lazy-lock.json`; never commit downloaded plugin/state/cache
  directories.
- Keep Oh My Zsh and Codex pins in `versions.env`.
- When changing the theme, inspect Zsh, tmux, Neovim, Windows Terminal, cheat sheets, and docs
  for palette drift.
- ANSI terminal green may intentionally map to red for visibility. Neovim semantic green may
  remain green; document this distinction.
- Protect `Space ?`, the responsive cheat-sheet layout, WSL clipboard mappings, `Ctrl-q` Visual
  Block, tmux `Ctrl-a`, and the `tma` multi-client session workflow.

## Documentation requirements

Cheat sheets and operational documentation are product features, not optional commentary.
Update affected documentation whenever a command, phase, path, shortcut, restart point,
dependency, security boundary, or troubleshooting workflow changes.

New user-facing operations belong in both the relevant detailed guide and the compact cheat
sheet when they are used repeatedly.

## Verification

Before completion:

```bash
tests/run.sh
git diff --check
git status --short
```

Behavior changes require a focused test. At minimum preserve:

- Bash and Zsh syntax checks.
- ShellCheck.
- JSON parsing.
- Isolated-home linker and backup checks.
- Secret and personal-path scan.
- Neovim lockfile parsing.

Report tests that could not run and why.

## Change discipline

- Keep changes narrow and review the full diff before committing.
- Do not rewrite user-authored documentation or configuration unrelated to the task.
- Update `CHANGELOG.md` for user-visible changes.
- Use `main` as the default branch and Conventional Commit-style summaries where useful.
- Public releases must not be published until the secret scan and isolated-home tests pass.
