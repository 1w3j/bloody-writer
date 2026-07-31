# Changelog

All notable changes to Bloody Writer are documented here.

## [Unreleased]

## [0.2.0] - 2026-07-31

### Added

- First-class native Termux on Android installation with automatic platform detection, `pkg`
  manifest, Zsh/tmux/Neovim/GitHub tools, Android clipboard/storage, font, and palette.
- Safe Windows host-theme phase that installs a verified user Nerd Font and separate Windows
  Terminal fragment/profile without rewriting existing settings.
- Recorded manual checkpoints for WSL/Windows Terminal and Android permission/app pauses, with
  status text and rerun-to-resume behavior.
- Public Bloody Writer logo, WSL hero/gallery screenshots, and an Oh My Zsh-inspired README
  structure with explicit platform/capability tables.
- Comprehensive Termux, customization/publishing, cross-platform install, remote access, and
  capability-oriented cheat-sheet documentation.

### Changed

- `tma` now has friendly help, exact session targets, `Ctrl-X`/fallback kill actions, and mandatory
  one-key confirmation before killing a selected tmux session.
- tmux and Neovim clipboard integration now dispatches automatically to Windows WSL or Termux:API.
- `bloody-writer remote` now configures either the WSL Tailscale SSH host or the Termux Android
  client according to the detected environment.
- Codex is explicitly local to WSL; Termux uses the supported remote WSL/tmux workflow and never
  installs an unofficial Android build.

## [0.1.0] - 2026-07-31

### Added

- Resumable Arch WSL installer with restart checkpoints and per-phase state.
- Fresh-root user bootstrap with systemd, default-user, sudo, and interop configuration.
- Bloody Writer Zsh/Agnoster, tmux, Neovim, and terminal theme snapshot.
- Locked plugins, verified spell assets, pinned Oh My Zsh/Codex, GitHub SSH setup, backups, tests,
  CI, and optional Termux-to-WSL Tailscale SSH access.
