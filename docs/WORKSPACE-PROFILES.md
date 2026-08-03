# Project workspace profiles

Workspace profiles reproduce a project's **development capability** on top of Bloody Writer's
Zsh/tmux/Neovim/Codex/GitHub experience. They do not clone private repositories, migrate
credentials, or snapshot runtime state.

Profiles are supported only on the official Arch Linux distribution under Windows WSL 2. Native
Termux on Android keeps full Bloody Writer base support, including remote tmux access to WSL, but
every workspace operation stops before mutation with a WSL-only message.

## Fresh-machine sequence

1. In the fresh Arch WSL root shell, clone public Bloody Writer and run `./install.sh`.
2. Follow the displayed PowerShell `wsl --terminate` checkpoint and reopen the distribution.
3. Resume as the new normal user. Complete GitHub, SSH-key, and Codex authentication yourself.
4. At the private-project checkpoint, clone the project explicitly:

   ```bash
   mkdir -p ~/projects
   gh repo clone OWNER/PRIVATE-PROJECT ~/projects/PRIVATE-PROJECT
   ```

5. Validate and apply its reviewed profile:

   ```bash
   bloody-writer workspace validate ~/projects/PRIVATE-PROJECT/bloody-writer.workspace.json
   bloody-writer install --workspace ~/projects/PRIVATE-PROJECT/bloody-writer.workspace.json
   ```

6. If a host-owned checkpoint interrupts installation, finish the displayed action and run:

   ```bash
   bloody-writer workspace resume --yes
   ```

Passing a workspace profile from the root shell stops and prints this safe order. The installer
does not copy a private repository, authentication state, or keys from `/root`.

## Command map

| Command | Result |
|---|---|
| `bloody-writer install -w FILE` | Complete/resume the base, then apply the profile |
| `bloody-writer workspace scan --project DIR --output FILE` | Write a deterministic `candidate` for human review |
| `bloody-writer workspace validate FILE` | Check the complete approved/tracked profile without mutation |
| `bloody-writer workspace audit FILE` | Compare packages, commands, PHP modules, versions, and system files |
| `bloody-writer workspace apply FILE` | Run only the workspace layer after a complete base install |
| `bloody-writer workspace status` | Show the active manifest/digest and four phase states |
| `bloody-writer workspace resume` | Continue the active profile generation |
| `bloody-writer workspace help` | Show concise usage and safety boundaries |

`--dry-run` previews apply/install operations without packages, files, commands, trust state, or
phase markers. `--force` deliberately reruns completed workspace phases. `--yes` accepts only the
visible profile trust prompt; it never answers a password or authentication flow.

`bloody-writer update` remains base-only unless `--workspace FILE` is present. A base-only update
prints the active workspace generation state instead of silently rerunning project setup.

## Schema version 1

The public schema is [`schemas/workspace-profile-v1.schema.json`](../schemas/workspace-profile-v1.schema.json).
JSON stays human-readable and `jq` supplies strict parsing without shell evaluation.

| Section | Declares |
|---|---|
| `profile` | Stable ID/name, minimum Bloody Writer version, `candidate` or `approved` review state |
| `platform` | Exactly Arch Linux, WSL, version 2 |
| `packages` | Sorted unique pacman and optional global npm package lists |
| `versions` | Requirement plus tracked project source for PHP, Node.js, and pnpm |
| `requirements` | Sorted required commands and PHP extensions |
| `system_files` | Controlled adapter/source/destination mappings |
| `environment_guard` | Required local/SQLite/loopback setup policy and SQLite backup |
| `lifecycle` | Setup, verification, and documented development argument arrays |
| `ports` | Loopback listener metadata; no firewall or service enablement |
| `capabilities` | Dependency on the complete Bloody Writer base |

Version 1 permits only a tracked regular project source mapped by the `php-conf` adapter to an
`.ini` file beneath `/etc/php/conf.d/`. A differing destination is copied into the manifest
generation's private backup tree before replacement. Adding any other system adapter requires a
new reviewed implementation, tests, and security documentation—not just a new JSON value.

Lifecycle values look like this:

```json
{
  "argv": ["composer", "run", "setup"]
}
```

The array is executed directly from the project root with `TMPDIR=/tmp`. Bloody Writer never
uses `eval`, `source`, string interpolation, or `sh -c` for a profile command. Version 1 also
rejects path-qualified executables, control characters, shell interpreters, and delegation or
privilege wrappers (`sh`, `bash`, `zsh`, `dash`, `fish`, `ksh`, `env`, `sudo`, `doas`, `su`, and
`command`) as `argv[0]`. Composer lifecycle commands require a tracked, regular, committed-clean
`composer.json`; pnpm/npm commands have the same requirement for `package.json`. This protects
the reviewed Git commit without requiring unrelated application files to be clean.

The documented development entrypoint is printed after installation and is never started by the
installer.

## Validation and trust

Before any profile mutation, Bloody Writer rejects:

- Termux, root, unsupported Linux, non-Arch WSL, and WSL 1;
- files over 1 MiB, malformed JSON, unknown keys/schema versions, and candidate profiles;
- unsorted/duplicate lists, unsafe package names, symlinks, and path traversal;
- profiles outside Git, untracked profiles, and untracked/missing/non-regular referenced sources;
- destinations outside the defined version-1 adapter;
- a profile requiring a newer Bloody Writer version.

Validation displays the project root, current Git commit, profile ID, and manifest SHA-256. Apply
asks the user to trust that exact generation. Editing the manifest changes its digest, starts a
new state generation, and requires validation/trust again.

## Guarded project setup

If `.env` is absent, the approved setup command may create it. If present, Bloody Writer reads
only the local guard fields without sourcing the file and requires:

```dotenv
APP_ENV=local
APP_URL=http://127.0.0.1:8080
DB_CONNECTION=sqlite
```

`localhost` and `::1` are also loopback. An existing local SQLite database is copied into private
workspace state before setup/migrations. Database contents, `.env` values, keys, and identities
are never added to the profile.

## Resume and recovery state

```text
~/.local/state/bloody-writer/workspaces/
├── active.json                         # mode 0600; local locator + exact digest
└── <profile-id>/<manifest-sha256>/
    ├── completed/
    │   ├── workspace-packages
    │   ├── workspace-system-files
    │   ├── workspace-project-setup
    │   └── workspace-verify
    └── backups/
        ├── system-files/etc/php/conf.d/...
        └── sqlite/...
```

A phase marker is created only after its operation verifies. A failed setup or verification is
left pending and resumes without pretending success.

## Curated scanning and review

The scanner is bounded to project runtime metadata, relevant packages from Arch's explicit
package query (`pacman -Qqe`), pacman owners of required installed commands, global npm providers,
supported matching tracked `/etc` fragments, standard Composer/pnpm scripts, required commands,
and existing Bloody Writer capabilities. It records package names—not install-reason state.
Output is sorted, timestamp-free, and always `candidate`. It refuses to overwrite a path and
reports explicitly when its `rg` prerequisite is unavailable.

It never scans or serializes `.env`, SQLite bytes, ignored/private evidence, `.idea`, authentication
state, SSH keys, Git identity, GitHub/Codex sessions, history, caches, dependencies, logs, tmux
sessions, usernames, hostnames, absolute home paths, or Obsidian destinations.

After scanning:

1. Review every package, source, command, listener, and exclusion.
2. Compare the candidate with project-owned environment/onboarding documentation.
3. Remove accidental or non-reproducible items.
4. Change `review_state` to `approved` only with project-owner authorization.
5. Commit the profile and every referenced source before validation/apply.

## Maintainer checklist

When changing the format or engine, keep these together:

- schema and strict parser;
- CLI help, this guide, cheat sheet, architecture, security, maintenance, and troubleshooting;
- focused malicious-input, scan-exclusion, direct-argv, backup, phase/resume, and platform tests;
- version bump/migration notes when compatibility changes.

Do not weaken tracked-file checks or add a general destination/command escape hatch for
convenience. Create a narrowly reviewed adapter instead.
