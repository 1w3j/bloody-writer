# Contributing

Contributions are welcome when they preserve Bloody Writer's security and portability boundary.

## Development

```bash
git clone https://github.com/1w3j/bloody-writer.git
cd bloody-writer
tests/run.sh
```

Use `./install.sh --dry-run` before testing system changes. For dotfile/linker work, rely on the
isolated temporary-home tests rather than replacing a real home configuration.

## Pull requests

- Explain the user problem and the behavior change.
- Keep phases idempotent and resumable.
- Add or update focused tests.
- Update operational docs and cheat sheets.
- Update `CHANGELOG.md` for user-visible behavior.
- Confirm that no secret, credential, personal path, history, or private data is included.

Run:

```bash
tests/run.sh
git diff --check
```

## Theme changes

Theme changes should include a contrast rationale and keep the palette synchronized across
Neovim, tmux, Zsh, Windows Terminal, and documentation where applicable.

## Security reports

Do not open a public issue for a credential exposure or remotely exploitable installer flaw.
Follow [SECURITY.md](SECURITY.md).
