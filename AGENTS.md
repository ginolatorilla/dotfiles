# AGENTS.md

This repo sets up the home directory of each Machine. chezmoi places the Dotfiles and Homebrew installs the Packages. macOS is the primary Platform. Linux under WSL 2 is the secondary Platform.

## Read first

- `docs/CONTEXT.md`: the glossary. Use its terms (Machine, Platform, Checkout, Dotfile, Package, Local override, Setup, Drift, Private, Secret) in code, commits and docs.
- `docs/adr/`: the decisions about Platform support, the package manager and Private items. Read the ADRs before you change these areas.

## Public repo

The GitHub repo is public. Each tracked line is published.

- Put Private items (organisation names, internal tools, internal hostnames) only in Local overrides: the `*.local` files and `~/.Brewfile.local`.
- Write home paths as `$HOME`, `~` or a chezmoi variable. An absolute path such as `/Users/<name>` shows the account name.
- Report only the path and the kind of a Secret. Never print, copy or track the value of a Secret.
- Before each commit, search the diff for Private names and absolute home paths.

## Dotfiles

- The chezmoi source is `home/`, set by `.chezmoiroot`. chezmoi runs in symlink mode.
- In symlink mode, each Dotfile in the home directory is a symlink into this Checkout. An edit to the Dotfile is an edit to the repo.
- Templates, `private_` files and `executable_` files are copies, not symlinks. The `readonly_` attribute has no effect in symlink mode.
- Put `.chezmoiignore` inside `home/`. chezmoi ignores all other source files whose names start with a dot.
- Live Dotfiles can be ahead of the repo, because tools such as lean-ctx and Claude Code add blocks to them. Run `chezmoi status` before you change a Dotfile.
- Review the edits that tools made in `git status` before you commit.

## Platforms

- Make each Dotfile work on macOS and on Linux (WSL 2, Ubuntu 24.04).
- Use the conditional syntax of the file format first. Use a chezmoi template only if the format has no conditional syntax.
- Look for Homebrew in `/opt/homebrew` and in `/home/linuxbrew/.linuxbrew`.
- On WSL, use only Linux mechanisms: OSC 52 for the clipboard, a terminal pinentry and a Linux ssh agent. Then native Linux also works.
- Keep `IgnoreUnknown UseKeychain` as the first line of the ssh config. OpenSSH on Linux stops on unknown options.

## Keybindings

`docs/cheatsheet.md` is the single source of truth for the keys of Ghostty, Zellij, nvim and fish. It shows the key path: which layer reads each key first.

- Give each key one owner. Before you add or change a key, find it in `docs/cheatsheet.md` and in the config of each tool. If two tools bind the same key, move one of them.
- Choose keys that no macOS system shortcut uses. Choose keys that also work in the WSL terminal, or record the difference in the cheatsheet.
- When a Cmd shortcut or an Option key goes through Ghostty, check that the byte sequence that Ghostty sends is not the sequence of another key (for example, Cmd+B and Option+Left).
- Update `docs/cheatsheet.md` in the same commit as each keybinding change, in Ghostty, Zellij, nvim or fish. Add, change and remove rows, and correct the key path diagram if a layer changes.
- Before you finish, compare the cheatsheet with the configs. Each key in one must be in the other.

## Packages

- List each Package in `home/dot_Brewfile`, including the `go`, `npm`, `uv` and `krew` entries. List Private Packages in `~/.Brewfile.local`.
- Put casks and macOS-only formulae under `if OS.mac?`. On Linux, `brew bundle` tries to install casks and fails.
- Put Linux-only entries under `if OS.linux?`. Put `winget` entries under `if OS.wsl?`.
- `brew bundle cleanup --force` also removes unlisted Go, npm, uv, krew and cargo packages. Run the command without `--force` first and read the list.
- `brew bundle --global` reads `~/.Brewfile` if `XDG_CONFIG_HOME` is not set.

## install.sh

- After each change to `install.sh`, run `tests/install_test.sh` and `shellcheck install.sh tests/install_test.sh`. The test uses a scratch home directory and stubs. It does not change this Machine.
- Keep `install.sh --check` read-only. It must not install a Package, clone the repo or write a file.
- When you add a step to Setup, add the same step to `--check`. `--check` exits with status 0 only if Setup would change nothing.
- Keep `install.sh` compatible with bash 3.2. On a fresh Mac, `/bin/bash` runs it.

## Tool facts

Check the behaviour of the installed version before you rely on a tool feature:

- Homebrew: `brew <command> --help` and the docs in `$(brew --repository)/docs`.
- chezmoi: `chezmoi help <command>`. To test attribute behaviour, run chezmoi with `--source`, `--destination` and `--persistent-state` in a scratch directory.

## Commits

- Write only a subject line and a body in each commit message. Add no attribution trailer, such as `Co-Authored-By`.
