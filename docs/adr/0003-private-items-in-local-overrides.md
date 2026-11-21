---
status: accepted
date: 2026-11-21
---

# Private settings and Packages live only in Local overrides

The repo is public on GitHub, so nothing Private goes into tracked Dotfiles: internal tool names, organisation names, private Go module paths, git URL rewrites, and include paths under organisation folders. Every Dotfile that can include another file includes an untracked `*.local` file next to it (`~/.gitconfig.local`, `~/.ssh/config.local`, `config.fish.local`, `~/.bashrc.local`, `~/.Brewfile.local`). Those Local overrides hold the Private items. The shared Brewfile includes `~/.Brewfile.local`, so `brew bundle check` and `brew bundle cleanup` also see Private Packages, and do not report or remove them.

## Considered options

- **chezmoi templates with per-Machine data**: Private names end up in tracked templates, or need a separate untracked data file anyway.
- **A `work` branch** (the previous approach): it drifted from `main` and needed manual merges.
