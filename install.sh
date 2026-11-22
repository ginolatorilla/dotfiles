#!/usr/bin/env bash
#
# Do the Setup of this Machine from the dotfiles repo.
# Run `install.sh --help` for the usage.

set -euo pipefail

readonly DEFAULT_CHECKOUT="$HOME/github.com/ginolatorilla/dotfiles"
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/ginolatorilla/dotfiles.git}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
readonly BREW_PREFIXES=(/opt/homebrew /home/linuxbrew/.linuxbrew)
readonly APT_PACKAGES=(build-essential procps curl file git)

usage() {
    cat <<'EOF'
Usage: install.sh [--dotfiles-only] [--force] [--check] [--help]

Do the Setup of this Machine: bring it in line with the Checkout. A second
run changes nothing if nothing changed.

  (no option)       Install the prerequisites, Homebrew and chezmoi. Clone
                    the repo if there is no Checkout. Place the Dotfiles,
                    install the missing Packages and fish plugins, and make
                    Homebrew fish the login shell.
  --dotfiles-only   Place the Dotfiles only. Do not install the Packages and
                    do not change the login shell.
  --force           Let chezmoi overwrite or restore a Dotfile that changed in
                    the home directory, without asking. Without this option,
                    chezmoi asks, and Setup stops if there is no terminal.
  --check           Show the Drift: what Setup would change. Change nothing.
                    This also works before the first Setup. With
                    --dotfiles-only, show what `install.sh --dotfiles-only`
                    would change.
  --help            Show this help.

Exit status of --check: 0 if there is no Drift, 1 if there is Drift, 2 if
there is an error.

Environment:
  DOTFILES_DIR      The Checkout to use. Default: the directory of this
                    script if it is a Checkout, else
                    ~/github.com/ginolatorilla/dotfiles.
  DOTFILES_REPO     The URL to clone. Default: the GitHub repo over HTTPS.
  DOTFILES_BRANCH   The branch to clone. Default: main.
EOF
}

# The exit status for errors. --check uses 2, because 1 means Drift.
error_status=1

log() { printf '==> %s\n' "$*"; }
die() {
    printf 'Error: %s\n' "$*" >&2
    exit "$error_status"
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

is_checkout() { [ -f "$1/.chezmoiroot" ]; }

# Print the Checkout that holds this script. Return 1 if there is none, for
# example when the script comes from `curl ... | bash`.
script_checkout() {
    local src="${BASH_SOURCE[0]:-}" dir
    [ -n "$src" ] && [ -f "$src" ] || return 1
    dir="$(cd "$(dirname "$src")" && pwd)"
    is_checkout "$dir" || return 1
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

brew_fish() { printf '%s/bin/fish\n' "$(brew --prefix)"; }

# Print the apt packages that Homebrew on Linux needs and that are missing.
missing_apt_packages() {
    local pkg
    for pkg in "${APT_PACKAGES[@]}"; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed' ||
            printf '%s\n' "$pkg"
    done
}

install_apt_packages() {
    if ! command -v apt-get >/dev/null; then
        log "apt-get not found. Install these packages yourself: ${APT_PACKAGES[*]}"
        return 0
    fi
    local missing
    missing="$(missing_apt_packages)"
    [ -z "$missing" ] && return 0
    # shellcheck disable=SC2086 # One package name for each word.
    set -- $missing
    log "Installing $* with apt-get"
    sudo apt-get update
    sudo apt-get install -y "$@"
}

install_brew() {
    load_brew && return 0
    log "Installing Homebrew"
    local installer
    installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    with_tty /bin/bash -c "$installer"
    load_brew || die "Homebrew is not on PATH after the install."
}

has_brew_chezmoi() { brew list --formula chezmoi >/dev/null 2>&1; }

install_chezmoi() {
    has_brew_chezmoi && return 0
    log "Installing chezmoi"
    brew install chezmoi
}

# Stop if DOTFILES_DIR is something other than a Checkout.
require_checkout_or_nothing() {
    is_checkout "$DOTFILES_DIR" || [ ! -e "$DOTFILES_DIR" ] ||
        die "$DOTFILES_DIR exists but is not a Checkout of the dotfiles repo."
}

ensure_checkout() {
    is_checkout "$DOTFILES_DIR" && return 0
    log "Cloning $DOTFILES_REPO ($DOTFILES_BRANCH) to $DOTFILES_DIR"
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
}

# Generate the chezmoi config from home/.chezmoi.toml.tmpl and place the
# Dotfiles. The run_onchange scripts install the Packages when a Package
# list changes.
apply_dotfiles() {
    local args=(init --apply --source "$DOTFILES_DIR")
    if [ "$dotfiles_only" = true ]; then
        args+=(--exclude scripts)
        log "Placing the Dotfiles. Packages are skipped."
    else
        log "Placing the Dotfiles and installing the Packages"
    fi
    [ "$force" = false ] || args+=(--force)
    "$(brew --prefix)/bin/chezmoi" "${args[@]}"
}

brewfile() { printf '%s/home/dot_Brewfile\n' "$DOTFILES_DIR"; }

# Print the Packages in the Checkout's Brewfile and ~/.Brewfile.local that
# are missing. Return 1 if any are missing. Outdated Packages are not Drift.
check_bundle() {
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "$(brewfile)" --no-upgrade --verbose
}

# Print each line of $1, or nothing if $1 is empty.
print_lines() { [ -z "$1" ] || printf '%s\n' "$1"; }

# Print the installed fish plugins, as `fisher list` does: the values of the
# universal variable _fisher_plugins. Read them from fish_variables, because
# each start of fish can write files. fish separates the values with \x1e and
# writes other special characters as \xNN.
installed_fish_plugins() {
    local vars="${XDG_CONFIG_HOME:-$HOME/.config}/fish/fish_variables" value
    [ -f "$vars" ] || return 0
    value="$(sed -n 's/^SETUVAR _fisher_plugins://p' "$vars")"
    [ -z "$value" ] || printf '%b\n' "$value" | tr '\036' '\n'
}

# Print the fish plugins that `fisher update` would install (+) or remove
# (-). Return 1 if there are any.
fish_plugin_drift() {
    local listed installed drift_lines
    listed="$(sed '/^[[:space:]]*$/d' "$DOTFILES_DIR/home/dot_config/fish/fish_plugins" | LC_ALL=C sort)"
    installed="$(installed_fish_plugins | LC_ALL=C sort)"
    drift_lines="$(
        LC_ALL=C comm -23 <(print_lines "$listed") <(print_lines "$installed") | sed 's/^/+ /'
        LC_ALL=C comm -13 <(print_lines "$listed") <(print_lines "$installed") | sed 's/^/- /'
    )"
    [ -z "$drift_lines" ] && return 0
    printf '%s\n' "$drift_lines"
    return 1
}

# The run_onchange scripts install the Packages and fish plugins only when a
# Package list changes. Install the ones that were removed since.
repair_packages() {
    if ! check_bundle >/dev/null 2>&1; then
        log "Installing the missing Packages"
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file "$(brewfile)" --no-upgrade
    fi
    local fish
    fish="$(brew_fish)"
    [ -x "$fish" ] || die "$fish not found. Fix the brew bundle errors, then run install.sh again."
    if ! fish_plugin_drift >/dev/null; then
        log "Installing the missing fish plugins"
        "$fish" -c 'fisher update'
    fi
}

login_shell() {
    local user="${USER:-$(id -un)}"
    if [ "$(uname -s)" = Darwin ]; then
        id -P "$user" | cut -d: -f10
    else
        getent passwd "$user" | cut -d: -f7
    fi
}

set_login_shell() {
    local fish
    fish="$(brew_fish)"
    [ -x "$fish" ] || die "$fish not found. Fix the brew bundle errors, then run install.sh again."
    [ "$(login_shell)" = "$fish" ] && return 0
    if ! grep -qx "$fish" /etc/shells; then
        log "Adding $fish to /etc/shells"
        printf '%s\n' "$fish" | sudo tee -a /etc/shells >/dev/null
    fi
    log "Changing the login shell to $fish"
    with_tty chsh -s "$fish"
}

# --- --check: read-only -----------------------------------------------------

# Print one line of the --check report. Each status other than ok is Drift.
report() {
    printf '%-12s %s\n' "$1" "$2"
    [ "$1" = ok ] || drift=1
}

# Print the details of the last report line, indented.
details() { printf '%s\n' "$1" | sed 's/^/               /'; }

# Print the chezmoi to read the Dotfiles with: Homebrew's chezmoi, else the
# first chezmoi on PATH. Return 1 if there is none.
find_chezmoi() {
    if command -v brew >/dev/null && [ -x "$(brew --prefix)/bin/chezmoi" ]; then
        printf '%s/bin/chezmoi\n' "$(brew --prefix)"
        return 0
    fi
    command -v chezmoi
}

# Run chezmoi ($1) on the Checkout. Pass --mode symlink, so that the result
# does not depend on the chezmoi config; keep it the same as
# home/.chezmoi.toml.tmpl. Hide the chezmoi warning that the config template
# changed: the chezmoi config step reports that.
run_chezmoi() {
    local chezmoi="$1"
    shift
    {
        "$chezmoi" --source "$DOTFILES_DIR" --mode symlink "$@" 2>&1 1>&3 3>&- |
            sed '/config file template has changed/d' >&2
    } 3>&1
}

check_apt_packages() {
    if ! command -v apt-get >/dev/null; then
        report ok 'apt prerequisites: apt-get not found, so Setup skips this step'
        return
    fi
    local missing
    missing="$(missing_apt_packages)"
    if [ -z "$missing" ]; then
        report ok 'apt prerequisites'
    else
        report drift 'apt prerequisites: missing'
        details "$missing"
    fi
}

# Setup --dotfiles-only installs Homebrew's chezmoi. The full check reports
# it under Packages instead, because the Brewfile lists it.
check_brew_chezmoi() {
    if has_brew_chezmoi; then
        report ok "Homebrew's chezmoi"
    else
        report drift "Homebrew's chezmoi: not installed"
    fi
}

check_chezmoi_config() {
    local config="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml" want
    want="$(run_chezmoi "$1" execute-template --init --file "$DOTFILES_DIR/home/.chezmoi.toml.tmpl")" ||
        die "chezmoi cannot render home/.chezmoi.toml.tmpl."
    if [ ! -f "$config" ]; then
        report drift 'chezmoi config: missing'
    elif [ "$want" != "$(cat "$config")" ]; then
        report drift 'chezmoi config: differs from home/.chezmoi.toml.tmpl'
    else
        report ok 'chezmoi config'
    fi
}

check_dotfiles() {
    local args=(status) status
    if [ "$dotfiles_only" = true ]; then
        args+=(--exclude scripts)
    fi
    # chezmoi downloads each external to its cache. Use a scratch cache, so
    # that --check writes nothing to the home directory.
    local cache
    cache="$(mktemp -d)" || die "Cannot make a scratch directory."
    args+=(--cache "$cache")
    status="$(run_chezmoi "$1" "${args[@]}")" || {
        rm -rf "$cache"
        die "chezmoi status failed."
    }
    rm -rf "$cache"
    if [ -z "$status" ]; then
        report ok Dotfiles
    else
        report drift Dotfiles
        details "$status"
    fi
}

check_packages() {
    local out
    if out="$(check_bundle 2>&1)"; then
        report ok Packages
    else
        report drift Packages
        details "$out"
    fi
}

check_fish_plugins() {
    local out
    if out="$(fish_plugin_drift)"; then
        report ok 'fish plugins'
    else
        report drift 'fish plugins'
        details "$out"
    fi
}

check_login_shell() {
    local fish shell
    fish="$(brew_fish)"
    shell="$(login_shell)"
    if [ "$shell" = "$fish" ]; then
        report ok 'Login shell'
    else
        report drift "Login shell: $shell, not $fish"
    fi
}

# Read-only. Print one line for each Setup step: ok, drift, or not checked
# because an earlier step is missing. Set drift to 1 if there is Drift.
check_drift() {
    local have_brew=false have_checkout=false chezmoi
    drift=0
    require_checkout_or_nothing
    log "Checking this Machine against $DOTFILES_DIR"

    if [ "$(uname -s)" = Linux ]; then
        check_apt_packages
    fi
    if load_brew; then
        have_brew=true
        report ok Homebrew
    else
        report drift 'Homebrew: not installed'
    fi
    if [ "$dotfiles_only" = true ]; then
        if [ "$have_brew" = true ]; then
            check_brew_chezmoi
        else
            report 'not checked' "Homebrew's chezmoi: no Homebrew"
        fi
    fi
    if is_checkout "$DOTFILES_DIR"; then
        have_checkout=true
        report ok Checkout
    else
        report drift "Checkout: none at $DOTFILES_DIR"
    fi

    chezmoi="$(find_chezmoi)" || chezmoi=""
    if [ "$have_checkout" = false ]; then
        report 'not checked' 'chezmoi config: no Checkout'
        report 'not checked' 'Dotfiles: no Checkout'
    elif [ -z "$chezmoi" ]; then
        report 'not checked' 'chezmoi config: chezmoi not found'
        report 'not checked' 'Dotfiles: chezmoi not found'
    else
        check_chezmoi_config "$chezmoi"
        check_dotfiles "$chezmoi"
    fi

    [ "$dotfiles_only" = true ] && return 0
    if [ "$have_brew" = false ]; then
        report 'not checked' 'Packages: no Homebrew'
    elif [ "$have_checkout" = false ]; then
        report 'not checked' 'Packages: no Checkout'
    else
        check_packages
    fi
    if [ "$have_checkout" = true ]; then
        check_fish_plugins
    else
        report 'not checked' 'fish plugins: no Checkout'
    fi
    if [ "$have_brew" = true ]; then
        check_login_shell
    else
        report 'not checked' 'Login shell: no Homebrew'
    fi
}

main() {
    local mode=setup
    dotfiles_only=false
    force=false
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --check) mode=check ;;
        --dotfiles-only) dotfiles_only=true ;;
        --force) force=true ;;
        -h | --help)
            usage
            return 0
            ;;
        *)
            usage >&2
            error_status=2
            die "Unknown option: $1"
            ;;
        esac
        shift
    done

    DOTFILES_DIR="${DOTFILES_DIR:-$(script_checkout || printf '%s\n' "$DEFAULT_CHECKOUT")}"

    if [ "$mode" = check ]; then
        # Each unexpected failure, such as a set -e or set -u stop, exits
        # with 2, so that it does not look like Drift.
        error_status=2
        check_done=false
        trap '[ "$check_done" = true ] || exit 2' EXIT
        check_drift
        check_done=true
        exit "$drift"
    fi

    require_checkout_or_nothing
    if [ "$(uname -s)" = Linux ]; then
        install_apt_packages
    fi
    install_brew
    install_chezmoi
    ensure_checkout
    apply_dotfiles
    if [ "$dotfiles_only" = false ]; then
        repair_packages
        set_login_shell
    fi
    log "Done"
}

main "$@"
