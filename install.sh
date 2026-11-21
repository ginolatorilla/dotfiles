#!/usr/bin/env bash
#
# Set up the home directory of this Machine from the dotfiles repo.
# Run `install.sh --help` for the usage.

set -euo pipefail

readonly DEFAULT_CHECKOUT="$HOME/github.com/ginolatorilla/dotfiles"
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/ginolatorilla/dotfiles.git}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
readonly BREW_PREFIXES=(/opt/homebrew /home/linuxbrew/.linuxbrew)
readonly APT_PACKAGES=(build-essential procps curl file git)

usage() {
    cat <<'EOF'
Usage: install.sh [--dotfiles-only | --check | --help]

Set up a fresh Machine, or sync a Machine with the checkout. A second run
changes nothing if nothing changed.

  (no option)       Install the prerequisites, Homebrew and chezmoi. Clone
                    the repo if there is no checkout. Place the Dotfiles,
                    install the Packages and make Homebrew fish the login
                    shell.
  --dotfiles-only   Place the Dotfiles only. Do not install the Packages and
                    do not change the login shell.
  --check           Show the drift between this Machine and the checkout.
                    Change nothing. Exit with status 1 if there is drift.
  --help            Show this help.

Environment:
  DOTFILES_DIR      The checkout to use. Default: the directory of this
                    script if it is a checkout, else
                    ~/github.com/ginolatorilla/dotfiles.
  DOTFILES_REPO     The URL to clone. Default: the GitHub repo over HTTPS.
  DOTFILES_BRANCH   The branch to clone. Default: main.
EOF
}

log() { printf '==> %s\n' "$*"; }
die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

# Run a command with the terminal as stdin, so that it can prompt even when
# this script comes from `curl ... | bash`.
with_tty() {
    if [ -t 0 ]; then
        "$@"
    elif { : </dev/tty; } 2>/dev/null; then
        "$@" </dev/tty
    else
        "$@"
    fi
}

# Print the checkout that holds this script. Return 1 if there is none, for
# example when the script comes from `curl ... | bash`.
script_checkout() {
    local src="${BASH_SOURCE[0]:-}" dir
    [ -n "$src" ] && [ -f "$src" ] || return 1
    dir="$(cd "$(dirname "$src")" && pwd)"
    [ -f "$dir/.chezmoiroot" ] || return 1
    printf '%s\n' "$dir"
}

# Put Homebrew on PATH. Return 1 if Homebrew is not installed.
load_brew() {
    local prefix
    for prefix in "${BREW_PREFIXES[@]}"; do
        if [ -x "$prefix/bin/brew" ]; then
            eval "$("$prefix/bin/brew" shellenv)"
            return 0
        fi
    done
    command -v brew >/dev/null
}

# Homebrew on Linux needs these apt packages.
install_apt_packages() {
    if ! command -v apt-get >/dev/null; then
        log "apt-get not found. Install these packages yourself: ${APT_PACKAGES[*]}"
        return 0
    fi
    local missing=() pkg
    for pkg in "${APT_PACKAGES[@]}"; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed' ||
            missing+=("$pkg")
    done
    [ "${#missing[@]}" -eq 0 ] && return 0
    log "Installing ${missing[*]} with apt-get"
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
}

install_brew() {
    load_brew && return 0
    log "Installing Homebrew"
    local installer
    installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    with_tty /bin/bash -c "$installer"
    load_brew || die "Homebrew is not on PATH after the install."
}

install_chezmoi() {
    brew list --formula chezmoi >/dev/null 2>&1 && return 0
    log "Installing chezmoi"
    brew install chezmoi
}

ensure_checkout() {
    [ -f "$DOTFILES_DIR/.chezmoiroot" ] && return 0
    [ -e "$DOTFILES_DIR" ] && die "$DOTFILES_DIR exists but is not a checkout of the dotfiles repo."
    log "Cloning $DOTFILES_REPO ($DOTFILES_BRANCH) to $DOTFILES_DIR"
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
}

# Generate the chezmoi config from home/.chezmoi.toml.tmpl and place the
# Dotfiles. The run_onchange scripts install the Packages.
apply_dotfiles() {
    local args=(init --apply --source "$DOTFILES_DIR")
    if [ "$dotfiles_only" = true ]; then
        args+=(--exclude scripts)
        log "Placing the Dotfiles. Packages are skipped."
    else
        log "Placing the Dotfiles and installing the Packages"
    fi
    "$(brew --prefix)/bin/chezmoi" "${args[@]}"
}

login_shell() {
    if [ "$(uname -s)" = Darwin ]; then
        id -P "$USER" | cut -d: -f10
    else
        getent passwd "$USER" | cut -d: -f7
    fi
}

set_login_shell() {
    local fish
    fish="$(brew --prefix)/bin/fish"
    [ -x "$fish" ] || die "$fish not found. Fix the brew bundle errors, then run install.sh again."
    [ "$(login_shell)" = "$fish" ] && return 0
    if ! grep -qx "$fish" /etc/shells; then
        log "Adding $fish to /etc/shells"
        printf '%s\n' "$fish" | sudo tee -a /etc/shells >/dev/null
    fi
    log "Changing the login shell to $fish"
    with_tty chsh -s "$fish"
}

# Read-only. Print the Dotfiles that differ from the checkout and the
# Packages that are missing. Outdated Packages are not drift.
check_drift() {
    load_brew || die "Homebrew is not installed. Run install.sh first."
    local chezmoi status drift=0
    chezmoi="$(brew --prefix)/bin/chezmoi"
    [ -x "$chezmoi" ] || die "chezmoi is not installed. Run install.sh first."

    log "Dotfiles: chezmoi status"
    status="$("$chezmoi" --source "$DOTFILES_DIR" status)"
    if [ -n "$status" ]; then
        printf '%s\n' "$status"
        drift=1
    else
        echo "No drift."
    fi

    log "Packages: brew bundle check"
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --global --no-upgrade --verbose || drift=1

    return "$drift"
}

main() {
    local mode=setup
    dotfiles_only=false
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --check) mode=check ;;
        --dotfiles-only) dotfiles_only=true ;;
        -h | --help)
            usage
            return 0
            ;;
        *)
            usage >&2
            die "Unknown option: $1"
            ;;
        esac
        shift
    done

    DOTFILES_DIR="${DOTFILES_DIR:-$(script_checkout || printf '%s\n' "$DEFAULT_CHECKOUT")}"

    if [ "$mode" = check ]; then
        check_drift
        return
    fi

    if [ "$(uname -s)" = Linux ]; then
        install_apt_packages
    fi
    install_brew
    install_chezmoi
    ensure_checkout
    apply_dotfiles
    if [ "$dotfiles_only" = false ]; then
        set_login_shell
    fi
    log "Done"
}

main "$@"
