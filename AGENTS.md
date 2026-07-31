# Bloody Writer agent instructions

## Purpose and scope

Bloody Writer is a public, reproducible terminal configuration for Arch Linux on Windows WSL 2
and native Termux on Android. Preserve the true-black, blood-red, and warm-white design while
keeping installation safe, resumable, portable, and understandable on both platforms.

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

- Supported install targets are official Arch Linux under Windows WSL 2 and the main native
  Termux environment on Android. PRoot is an optional companion, not the installer target.
- Platform detection must happen before mutation. WSL uses `pacman`/`sudo`; Termux uses `pkg`
  and must reject root.
- Every phase must be idempotent and must mark completion only after successful verification.
- Any phase that needs WSL termination, Windows Terminal reload, Android permission, or a
  companion app must persist state, stop cleanly, print exact actions, and resume on rerun.
- Back up an existing user file before replacing it or creating a managed symlink.
- Validate destructive or move targets are inside the intended home directory.
- Do not silently overwrite existing Codex, SSH, GitHub, or personal settings.
- Account authentication and key passphrases remain interactive and user-owned.
- `bloody-writer update` must preserve fast-forward-only Git behavior and reject dirty checkouts.

## Configuration rules

- Keep personal values in `~/.config/bloody-writer/settings.zsh`, never in tracked dotfiles.
- Keep Neovim plugin commits in `lazy-lock.json`; never commit downloaded plugin/state/cache
  directories.
- Keep Oh My Zsh, Codex, and Nerd Font pins in `versions.env`.
- When changing the theme, inspect Zsh, tmux, Neovim, Windows Terminal, Termux properties,
  logo/screenshots, cheat sheets, and docs for palette drift.
- ANSI terminal green may intentionally map to red for visibility. Neovim semantic green may
  remain green; document this distinction.
- Protect `Space ?`, the responsive cheat-sheet layout, platform clipboard mappings, `Ctrl-q`
  Visual Block, tmux `Ctrl-a`, and the `tma` multi-client/confirmed-kill workflow.
- Do not claim native Android Codex support or install an unofficial Android build; route Termux
  users to the official WSL CLI through private SSH/tmux.

## Documentation requirements

Cheat sheets and operational documentation are product features, not optional commentary.
Update affected documentation whenever a command, phase, path, shortcut, restart point,
dependency, security boundary, or troubleshooting workflow changes.

New user-facing operations belong in both the relevant detailed guide and the compact cheat
sheet when they are used repeatedly.

Public screenshots require human pixel inspection for usernames, hostnames, private paths,
repository names, tokens, fingerprints, and notifications; text-only secret scans are insufficient.

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
