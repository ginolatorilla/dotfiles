---
status: accepted
date: 2026-11-21
---

# Homebrew installs Packages on Linux too

Linux Machines install Packages with Homebrew from the same Brewfile as macOS, not with apt. One list serves both Platforms. Versions match across Machines. Packages install without sudo once Homebrew is in place. `brew bundle` also covers Go, npm, uv and krew packages, so there is no second installer to maintain. Entries that only work on macOS (casks, `pinentry-mac`, `telnet`, `terminal-notifier`) sit under `if OS.mac?`.

## Considered options

- **Brewfile on macOS, apt on Linux**: two lists that drift apart, and Ubuntu versions lag behind.
- **Nix with home-manager**: one tool for Packages and Dotfiles on both Platforms, but heavier than the Ansible setup it would replace.

## Consequences

- Full Homebrew support on Linux needs glibc 2.39 or later, which Ubuntu 24.04 provides. Older distros fall to Tier 2.
- Linux needs `build-essential procps curl file git` from apt before Homebrew installs. This is the only sudo step.
