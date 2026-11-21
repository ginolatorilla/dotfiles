#!/usr/bin/env bash
#
# Test install.sh in a sandbox: a scratch HOME, a fake Homebrew prefix and
# stubs for the commands that change the system (brew, fish, chsh, sudo). The
# test never touches the real home directory and never installs a Package.
#
# Requirements: git, and chezmoi on PATH (or in $CHEZMOI).
# Usage: tests/install_test.sh. Set KEEP=1 to keep the scratch directory.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_CHEZMOI="${CHEZMOI:-$(command -v chezmoi || true)}"
[ -x "$REAL_CHEZMOI" ] || {
    echo "chezmoi not found. Put it on PATH or set CHEZMOI." >&2
    exit 2
}

T="$(mktemp -d "${TMPDIR:-/tmp}/install_test.XXXXXX")"
if [ "${KEEP:-0}" = 1 ]; then
    echo "Scratch directory: $T"
else
    trap 'rm -rf "$T"' EXIT
fi

FAKE="$T/prefix"   # The fake Homebrew prefix
STUBS="$T/bin"     # Stubs for system commands, first on PATH
LOG="$T/calls.log" # Each stub call
CHECKOUT="$T/home/github.com/ginolatorilla/dotfiles"
mkdir -p "$T/home" "$FAKE/bin" "$STUBS"
: >"$LOG"
echo /bin/zsh >"$T/login-shell"

# --- Stubs ---------------------------------------------------------------

# brew: Packages are missing while $FAKE/missing-packages exists.
cat >"$FAKE/bin/brew" <<EOF
#!/bin/bash
echo "brew \$*" >>"$LOG"
case "\$1" in
shellenv) echo "export HOMEBREW_PREFIX=$FAKE; export PATH=$FAKE/bin:\\\$PATH" ;;
--prefix) echo "$FAKE" ;;
list) [ -e "$FAKE/installed-\$3" ] ;;
install) touch "$FAKE/installed-\$2"; ln -sf "$REAL_CHEZMOI" "$FAKE/bin/chezmoi" ;;
bundle)
    if [ "\$2" = check ]; then
        [ -e "$FAKE/missing-packages" ] || exit 0
        cat "$FAKE/missing-packages"
        exit 1
    fi
    rm -f "$FAKE/missing-packages"
    ;;
*) echo "stub brew: unexpected \$*" >&2; exit 2 ;;
esac
EOF

# fish: `fisher update` writes the plugins in fish_plugins to the universal
# variable _fisher_plugins in fish_variables, with \x1e between the values.
cat >"$FAKE/bin/fish" <<'EOF'
#!/bin/bash
echo "fish $*" >>"@LOG@"
case "$2" in
'fisher update')
    vals=""
    while IFS= read -r plugin; do
        [ -n "$plugin" ] || continue
        vals="${vals:+$vals\\x1e}$plugin"
    done <"$HOME/.config/fish/fish_plugins"
    printf 'SETUVAR _fisher_plugins:%s\n' "$vals" >"$HOME/.config/fish/fish_variables"
    ;;
*) echo "stub fish: unexpected $*" >&2; exit 2 ;;
esac
EOF
sed -i.bak "s|@LOG@|$LOG|" "$FAKE/bin/fish"
rm "$FAKE/bin/fish.bak"

# id and getent: the login shell is in $T/login-shell. They fail while
# $T/broken exists.
cat >"$STUBS/id" <<EOF
#!/bin/bash
[ "\$1" = -P ] || exec /usr/bin/id "\$@"
[ ! -e "$T/broken" ] || exit 3
echo "\$2:*:501:20::0:0:Test:/home/test:\$(cat "$T/login-shell")"
EOF
cat >"$STUBS/getent" <<EOF
#!/bin/bash
[ "\$1" = passwd ] || exec /usr/bin/getent "\$@"
[ ! -e "$T/broken" ] || exit 3
echo "\$2:x:1000:1000:Test:/home/test:\$(cat "$T/login-shell")"
EOF
cat >"$STUBS/chsh" <<EOF
#!/bin/bash
echo "chsh \$*" >>"$LOG"
[ "\$1" = -s ] && echo "\$2" >"$T/login-shell"
EOF

# sudo: never runs the command. dpkg-query: each apt package is installed.
cat >"$STUBS/sudo" <<EOF
#!/bin/bash
echo "sudo \$*" >>"$LOG"
cat >/dev/null
EOF
cat >"$STUBS/dpkg-query" <<'EOF'
#!/bin/bash
echo 'install ok installed'
EOF

chmod +x "$FAKE/bin/"* "$STUBS/"*

# --- The repo under test -------------------------------------------------

# The origin to clone: the files of this working tree, with the Homebrew
# prefixes in the run_onchange scripts replaced by the fake prefix.
ORIGIN="$T/origin"
mkdir -p "$ORIGIN"
git -C "$REPO" ls-files -z --cached --others --exclude-standard |
    (cd "$REPO" && tar --null -T - -cf -) | tar -C "$ORIGIN" -xf -
for script in "$ORIGIN"/home/run_onchange_*; do
    sed -i.bak "s|^for brew_prefix in .*; do$|for brew_prefix in $FAKE; do|" "$script"
    rm "$script.bak"
    if grep -q -e /opt/homebrew -e /home/linuxbrew "$script"; then
        echo "Cannot point $script at the fake prefix." >&2
        exit 2
    fi
done
git -C "$ORIGIN" init -q -b main
git -C "$ORIGIN" add -A
git -C "$ORIGIN" -c user.name=test -c user.email=test@example.invalid \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q -m fixture

# install.sh with BREW_PREFIXES set to the fake prefix, or to a directory
# with no Homebrew.
make_install_sh() {
    sed "s|^readonly BREW_PREFIXES=.*|readonly BREW_PREFIXES=($2)|" "$REPO/install.sh" >"$1"
    chmod +x "$1"
    grep -q "^readonly BREW_PREFIXES=($2)$" "$1"
}
make_install_sh "$T/install.sh" "$FAKE"
make_install_sh "$T/install-nobrew.sh" "$T/no-homebrew"

# --- Helpers -------------------------------------------------------------

BASE_PATH="$STUBS:/usr/bin:/bin:/usr/sbin:/sbin"

# Run a command with the scratch HOME and a clean environment.
run() {
    env -i HOME="$T/home" USER="${USER:-$(id -un)}" PATH="${RUN_PATH:-$BASE_PATH}" TERM=dumb \
        DOTFILES_REPO="$ORIGIN" DOTFILES_BRANCH=main "$@" </dev/null
}

OUT="$T/out"
pass() { printf 'PASS %s\n' "$*"; }
fail() {
    printf 'FAIL %s\n--- output of the last install.sh run:\n' "$*"
    cat "$OUT" 2>/dev/null || true
    exit 1
}

# assert DESCRIPTION COMMAND...: COMMAND succeeds.
assert() {
    local what="$1"
    shift
    if "$@"; then pass "$what"; else fail "$what"; fi
}

# refute DESCRIPTION COMMAND...: COMMAND fails.
refute() {
    local what="$1"
    shift
    if "$@"; then fail "$what"; else pass "$what"; fi
}

# Run install.sh with the given arguments. Save the output in $OUT and the
# exit status in $STATUS. Set INSTALL_SH, RUN_PATH or DOTFILES_DIR_UNDER_TEST
# to change the run.
run_install_sh() {
    STATUS=0
    run env DOTFILES_DIR="${DOTFILES_DIR_UNDER_TEST:-}" "${INSTALL_SH:-$T/install.sh}" "$@" \
        >"$OUT" 2>&1 || STATUS=$?
}

expect_status() { assert "exit status $1 (got $STATUS)" [ "$STATUS" = "$1" ]; }

# expect_line STATUS LABEL: the --check report has a STATUS line for LABEL.
expect_line() { assert "report: $1 $2" grep -q "^$1  *$2" "$OUT"; }

expect_output() { assert "output has '$1'" grep -q -e "$1" "$OUT"; }
expect_no_output() { refute "output has no '$1'" grep -q -e "$1" "$OUT"; }
expect_call() { assert "called: $1" grep -q -x -e "$1" "$LOG"; }
expect_no_call() { refute "not called: $1" grep -q -e "$1" "$LOG"; }

# Print the number of detail lines under the report line for LABEL.
count_details() {
    sed -n "/^[a-z][a-z ]*  *$1/,/^[a-z]/p" "$OUT" | grep -c '^ ' || true
}

is_copy() { [ -f "$1" ] && [ ! -L "$1" ]; }

# Print the names of the files in the scratch HOME.
home_snapshot() { (cd "$T/home" && find . | sort); }

# Print the files in the scratch HOME that changed since $T/marker, except
# the Checkout and the chezmoi config and state.
home_changes() {
    (cd "$T/home" && find . \( -path ./github.com -o -path ./.config/chezmoi \) -prune \
        -o -newer "$T/marker" -print)
}

BREWFILE="$CHECKOUT/home/dot_Brewfile"
FISH="$FAKE/bin/fish"

# --- Tests ---------------------------------------------------------------

echo "== --check on a fresh Machine with no Homebrew and no Checkout"
before="$(home_snapshot)"
INSTALL_SH="$T/install-nobrew.sh" run_install_sh --check
expect_status 1
expect_line drift Homebrew
expect_line drift Checkout
expect_line 'not checked' 'chezmoi config'
expect_line 'not checked' Dotfiles
expect_line 'not checked' Packages
expect_line 'not checked' 'fish plugins'
expect_line 'not checked' 'Login shell'
expect_no_output 'install.sh'
assert "HOME unchanged" [ "$before" = "$(home_snapshot)" ]

echo "== --check before the first Setup reads the Dotfiles with a chezmoi from outside Homebrew"
echo '→ Formula chezmoi needs to be installed or updated.' >"$FAKE/missing-packages"
run git clone -q "$ORIGIN" "$CHECKOUT"
mkdir -p "$T/other-chezmoi"
ln -s "$REAL_CHEZMOI" "$T/other-chezmoi/chezmoi"
before="$(home_snapshot)"
: >"$LOG"
RUN_PATH="$BASE_PATH:$T/other-chezmoi" run_install_sh --check
expect_status 1
expect_line ok Homebrew
expect_line ok Checkout
expect_line drift 'chezmoi config: missing'
expect_line drift Dotfiles
expect_output '^ *A \.config/fish/config\.fish$'
expect_line drift Packages
expect_output 'Formula chezmoi needs to be installed'
expect_line drift 'fish plugins'
expect_output '+ jorgebucaran/fisher'
expect_line drift "Login shell: /bin/zsh, not $FISH"
expect_no_output 'install.sh'
expect_no_output 'config file template has changed'
expect_call "brew bundle check --file $BREWFILE --no-upgrade --verbose"
expect_no_call '^fish '
assert "HOME unchanged" [ "$before" = "$(home_snapshot)" ]
rm -rf "$CHECKOUT"

echo "== Setup --dotfiles-only on a fresh Machine"
: >"$LOG"
run_install_sh --dotfiles-only
expect_status 0
assert "cloned the Checkout to the default path" [ -f "$CHECKOUT/.chezmoiroot" ]
expect_call 'brew install chezmoi'
assert "config.fish is a symlink" [ -L "$T/home/.config/fish/config.fish" ]
case "$(readlink "$T/home/.config/fish/config.fish")" in
"$CHECKOUT/home/"*) pass "the symlink points into the Checkout" ;;
*) fail "symlink target: $(readlink "$T/home/.config/fish/config.fish")" ;;
esac
assert "gpg-agent.conf is a copy" is_copy "$T/home/.gnupg/gpg-agent.conf"
assert "the chezmoi config names the Checkout" \
    grep -q "sourceDir = \"$CHECKOUT\"" "$T/home/.config/chezmoi/chezmoi.toml"
assert "the chezmoi config selects symlink mode" \
    grep -q 'mode = "symlink"' "$T/home/.config/chezmoi/chezmoi.toml"
expect_no_call 'brew bundle install'
expect_no_call 'fisher update'
expect_no_call chsh

echo "== A second Setup --dotfiles-only changes nothing"
cp "$T/home/.config/chezmoi/chezmoi.toml" "$T/chezmoi.toml.1"
touch "$T/marker"
: >"$LOG"
run_install_sh --dotfiles-only
expect_status 0
assert "no file in HOME changed" [ -z "$(home_changes)" ]
assert "the chezmoi config is the same" cmp -s "$T/chezmoi.toml.1" "$T/home/.config/chezmoi/chezmoi.toml"
expect_no_call 'brew install'
expect_no_output Cloning

echo "== --check --dotfiles-only after Setup --dotfiles-only finds no Drift"
run_install_sh --check --dotfiles-only
expect_status 0
expect_line ok Homebrew
expect_line ok "Homebrew's chezmoi"
expect_line ok Checkout
expect_line ok 'chezmoi config'
expect_line ok Dotfiles
expect_no_output Packages
expect_no_output 'Login shell'

echo "== --check after Setup --dotfiles-only finds what the full Setup would do"
: >"$LOG"
run_install_sh --check
expect_status 1
expect_line ok 'chezmoi config'
expect_line drift Dotfiles
assert "the Dotfiles Drift is only the 2 pending scripts" [ "$(count_details Dotfiles)" = 2 ]
expect_output '^ *R brew-bundle\.sh$'
expect_output '^ *R fisher-update\.sh$'
expect_line drift Packages
expect_line drift 'fish plugins'
expect_line drift 'Login shell'

echo "== Setup installs the Packages and changes the login shell"
: >"$LOG"
run_install_sh
expect_status 0
expect_call 'brew bundle --global'
expect_call "fish -c fisher update"
expect_call "chsh -s $FISH"
run_install_sh --check
expect_status 0
expect_line ok Dotfiles
expect_line ok Packages
expect_line ok 'fish plugins'
expect_line ok 'Login shell'

echo "== Setup repairs the Packages and fish plugins that changed by hand"
echo '→ Formula jq needs to be installed or updated.' >"$FAKE/missing-packages"
printf 'SETUVAR _fisher_plugins:other/plugin\\x1eanother/plugin\n' >"$T/home/.config/fish/fish_variables"
: >"$LOG"
run_install_sh --check
expect_status 1
expect_line drift Packages
expect_output 'Formula jq needs to be installed'
expect_line drift 'fish plugins'
expect_output '^ *+ jorgebucaran/fisher$'
expect_output '^ *- other/plugin$'
expect_output '^ *- another/plugin$'
expect_line ok Dotfiles
expect_no_call '^fish '
: >"$LOG"
run_install_sh
expect_status 0
expect_call "brew bundle install --file $BREWFILE --no-upgrade"
expect_call "fish -c fisher update"
run_install_sh --check
expect_status 0

echo "== A second full Setup changes nothing"
touch "$T/marker"
: >"$LOG"
run_install_sh
expect_status 0
assert "no file in HOME changed" [ -z "$(home_changes)" ]
expect_no_call 'brew bundle install'
expect_no_call 'brew bundle --global'
expect_no_call 'fisher update'
expect_no_call chsh
expect_no_call sudo

echo "== --check finds a deleted Dotfile"
rm "$T/home/.vimrc"
run_install_sh --check
expect_status 1
expect_line drift Dotfiles
expect_output '\.vimrc'
ln -s "$CHECKOUT/home/dot_vimrc" "$T/home/.vimrc"

echo "== --check after Setup with a chezmoi from outside Homebrew"
rm "$FAKE/bin/chezmoi" "$FAKE/installed-chezmoi"
echo '→ Formula chezmoi needs to be installed or updated.' >"$FAKE/missing-packages"
RUN_PATH="$BASE_PATH:$T/other-chezmoi" run_install_sh --check
expect_status 1
expect_line ok 'chezmoi config'
expect_line ok Dotfiles
expect_line drift Packages
expect_no_output 'install.sh'
RUN_PATH="$BASE_PATH:$T/other-chezmoi" run_install_sh --check --dotfiles-only
expect_status 1
expect_line drift "Homebrew's chezmoi: not installed"
expect_line ok Dotfiles
run_install_sh --check
expect_status 1
expect_line 'not checked' 'Dotfiles: chezmoi not found'
ln -s "$REAL_CHEZMOI" "$FAKE/bin/chezmoi"
touch "$FAKE/installed-chezmoi"
rm "$FAKE/missing-packages"

echo "== Errors"
mkdir -p "$T/not-a-checkout"
DOTFILES_DIR_UNDER_TEST="$T/not-a-checkout" run_install_sh --dotfiles-only
expect_status 1
expect_output 'is not a Checkout'
DOTFILES_DIR_UNDER_TEST="$T/not-a-checkout" run_install_sh --check
expect_status 2
run_install_sh --no-such-option
expect_status 2
touch "$T/broken"
run_install_sh --check
expect_status 2
rm "$T/broken"
run_install_sh --check
expect_status 0

echo "== Running install.sh from a Checkout uses that Checkout"
cp "$T/install.sh" "$CHECKOUT/install-under-test.sh"
INSTALL_SH="$CHECKOUT/install-under-test.sh" run_install_sh --dotfiles-only
expect_status 0
expect_no_output Cloning
rm "$CHECKOUT/install-under-test.sh"

echo "All tests passed."
