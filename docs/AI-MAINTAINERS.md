# Working on Bloody Writer with AI agents

This is the shared orientation guide for a human maintainer and any coding agent working on the
repository. The root [`AGENTS.md`](../AGENTS.md) is the mandatory machine-facing contract; this
guide explains how to give an agent a useful task and where both humans and agents find evidence.

## Source-of-truth order

When information conflicts, use this order:

1. The maintainer's current explicit request and security decisions.
2. Root [`AGENTS.md`](../AGENTS.md).
3. Current tracked behavior, tests, `versions.env`, and accepted documentation.
4. Historical screenshots and old AI conversations as context only.

An agent must not treat a previous chat, screenshot, generated plan, or its own proposal as
authority to expose credentials, broaden platform support, or make destructive changes.

## The first prompt to give an AI agent

Copy this and replace the task paragraph:

```text
Work in the Bloody Writer repository. Read AGENTS.md completely, then read
docs/AI-MAINTAINERS.md and only the task-specific documents it routes you to. Inspect the
working tree and preserve unrelated changes.

Task: <describe the user-visible outcome, supported platform, and constraints>

Trace current behavior before editing. Keep WSL and Termux differences explicit, preserve the
credential boundary, add focused tests, update operational docs and CHANGELOG.md, run
tests/run.sh plus git diff --check, and report changed files, verification, platform impact,
security impact, and remaining risks. Do not publish or merge unless I explicitly request it.
```

Give acceptance examples when possible—for example, the exact command, expected prompt, files
that may change, and behavior that must remain unchanged. Attach terminal output rather than
asking the agent to guess an error.

## Repository map

| Area | Source of truth | Why to read it |
|---|---|---|
| Agent contract | `AGENTS.md` | Safety, platform, verification, and documentation rules |
| Command surface | `bin/bloody-writer`, `install.sh` | CLI parsing, update/resume dispatch, phase order |
| Shared installer behavior | `scripts/lib/common.sh` | Platform detection, state, prompts, backups, linking |
| Installation phases | `scripts/phases/NN-name.sh` | Idempotent WSL/Termux operations and checkpoints |
| Package/version inputs | `manifests/`, `versions.env`, Neovim `lazy-lock.json` | Reproducibility anchors |
| Active configuration | `dotfiles/`, `terminal/`, `windows/` | Zsh, tmux, Neovim, Android and Windows visual layers |
| User operations | `docs/CHEATSHEET.md`, `docs/TROUBLESHOOTING.md` | Repeated commands and recovery procedures |
| Architecture/security | `docs/ARCHITECTURE.md`, `docs/SECURITY-MODEL.md` | Ownership, state, trust and credential boundaries |
| Customization/releases | `docs/CUSTOMIZING.md`, `docs/MAINTENANCE.md`, `CONTRIBUTING.md` | Safe modification, lock updates, review and release |
| Behavior proof | `tests/`, `.github/workflows/ci.yml` | Regression contract and public-repository checks |

All managed configuration is linked from the Git checkout. Device-local settings, installer
state, downloads, credentials, and caches live outside it. Read the installed-state table in
[`ARCHITECTURE.md`](ARCHITECTURE.md) before changing ownership or paths.

## Read only what the task needs

| Task | Must read after this guide |
|---|---|
| Installer phase or platform detection | `docs/INSTALL.md`, `docs/ARCHITECTURE.md`, `docs/SECURITY-MODEL.md`, relevant phase and tests |
| Termux on Android | `docs/TERMUX-ANDROID.md`, relevant phase, platform tests |
| Arch Linux on Windows WSL or host theme | `docs/WINDOWS-TERMINAL.md`, relevant phase/PowerShell script and tests |
| Updates, Git state, recovery | `docs/MAINTENANCE.md`, update section in `bin/bloody-writer`, `tests/test-update.sh` |
| Neovim/plugin changes | `docs/CUSTOMIZING.md`, Neovim config, `scripts/update-neovim-lock.sh`, lockfile checks |
| tmux/remote phone workflow | `docs/REMOTE-ACCESS.md`, `tma`, tmux config, their focused tests |
| Theme/palette/showcase | `docs/CUSTOMIZING.md`, every palette surface, README assets; inspect pixels manually |
| Credentials, GitHub, SSH, Codex | `docs/SECURITY-MODEL.md`, relevant phase; never import private state |
| Workspace profile, scanner, or project layer | `docs/WORKSPACE-PROFILES.md`, schema, `scripts/lib/workspace.sh`, `tests/test-workspace.sh` |

Use `rg` to follow a command, variable, phase name, or palette value before expanding context.

## Change protocol

1. **Orient:** inspect branch/status and identify whether existing changes belong to the user.
2. **Trace:** reproduce or read the current behavior and its focused test.
3. **Define the boundary:** name the affected platform(s), files, state paths, secrets boundary,
   manual checkpoints, and backward-compatibility expectation.
4. **Implement:** keep phases rerunnable; make operating-system actions explicit; never silently
   replace authored settings.
5. **Prove:** add a focused test that would fail before the fix. Prefer temporary homes and local
   Git remotes over changing the maintainer's machine.
6. **Explain:** update the detailed guide, the cheat sheet for repeated operations, and the
   changelog for user-visible behavior.
7. **Review:** inspect the complete diff and run the repository verification contract.
8. **Handoff:** report what changed, tests, WSL/Termux impact, security impact, remaining risk,
   branch/commit/PR state, and any manual device validation still needed.

## Stable contracts for future upgrades

- Keep one root `AGENTS.md`; link new domain guides from this document instead of scattering
  competing agent instructions through subdirectories.
- A fresh clone plus tracked documentation must be enough to understand the current system.
- Keep CLI help, cheat sheets, detailed docs, tests, and implementation synchronized.
- Treat project profiles as untrusted data: retain exact-key parsing, direct argument-array
  execution, tracked-file checks, platform/root rejection, digest generations, and adapter-only
  privileged writes. A future schema version requires an explicit parser and migration review.
- Keep phases ordered, named, idempotent, and marked complete only after verification.
- Preserve `git pull --ff-only` and the updater's freshly-pulled self-relaunch.
- Add an automatic dirty-file repair only for deterministic generated drift, with an exact path,
  a recovery copy and patch, and regression coverage. Protect every unknown or staged change.
- Normal Neovim runs use a device-local lock copy. Only
  `scripts/update-neovim-lock.sh` intentionally updates the reviewed repository lock.
- Introduce a migration and documentation when changing phase names, state format, managed paths,
  supported platforms, or private-setting variables.
- Never claim completion for WSL-only or Termux-only behavior without naming which side was tested.

## Verification and handoff template

Run from the repository root:

```bash
tests/run.sh
git diff --check
git status --short
```

Then hand back this evidence:

```text
Outcome:
Changed files and behavior:
Tests/checks:
Arch Linux on Windows WSL impact:
Termux on Android impact:
Security/credential impact:
Documentation updated:
Manual validation still needed:
Branch / commit / pull request:
```

Publishing is a separate permission. An agent may prepare and test changes when asked to modify
the repository, but it should commit, push, open a pull request, merge, release, or delete remote
content only when the maintainer authorizes that action.
