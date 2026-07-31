# Upstream primary sources

Bloody Writer's installation and operations guidance is based on authoritative upstream material.

## Windows WSL and Terminal

- [Microsoft: Install WSL](https://learn.microsoft.com/windows/wsl/install)
- [Microsoft: Basic WSL commands](https://learn.microsoft.com/windows/wsl/basic-commands)
- [Microsoft: Windows Terminal JSON fragments](https://learn.microsoft.com/windows/terminal/json-fragment-extensions)
- [Microsoft: Windows Terminal color schemes](https://learn.microsoft.com/windows/terminal/customize-settings/color-schemes)
- [Microsoft: terminal prompt and Nerd Font setup](https://learn.microsoft.com/windows/terminal/tutorials/custom-prompt-setup)
- [ArchWiki: Install Arch Linux on WSL](https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL)
- [ArchWiki: Pacman](https://wiki.archlinux.org/title/Pacman)

## Termux on Android

- [Official Termux app repository and install notes](https://github.com/termux/termux-app)
- [Official Termux packages and package-management wiki](https://github.com/termux/termux-packages/wiki/package-management)
- [Official Termux:API app](https://github.com/termux/termux-api)
- [Official Termux PRoot Distro](https://github.com/termux/proot-distro)

Install Termux and its companion apps from one source; upstream documents that F-Droid and GitHub
builds use different signatures.

## Workspace tools

- [Oh My Zsh repository](https://github.com/ohmyzsh/ohmyzsh)
- [Oh My Zsh themes](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes)
- [Neovim documentation](https://neovim.io/doc/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [tmux getting started](https://github.com/tmux/tmux/wiki/Getting-Started)
- [tmux FAQ and true color](https://github.com/tmux/tmux/wiki/FAQ)
- [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases)

## Codex, GitHub, and remote access

- [OpenAI Codex repository](https://github.com/openai/codex)
- [OpenAI Codex standalone installer](https://chatgpt.com/codex/install.sh)
- [GitHub: generate and add an SSH key](https://docs.github.com/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-agent)
- [GitHub CLI manual](https://cli.github.com/manual/)
- [Tailscale on Linux](https://tailscale.com/docs/install/linux)
- [Tailscale on Android](https://tailscale.com/docs/install/android)

`versions.env` and `lazy-lock.json` are the repository's concrete snapshot anchors. Package
manifests follow the current Arch and Termux repositories. When historical chat context conflicts
with current files or primary documentation, tracked behavior and current upstream guidance win.
