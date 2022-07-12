#!/usr/bin/env bash

shopt -s expand_aliases
alias warn='echo $(tput setaf 3)▲ $(tput sgr0)'
alias inform='echo $(tput setaf 4)ℹ $(tput sgr0)'
alias check='echo $(tput setaf 2)✔ $(tput sgr0)'

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$DOTFILE_DIR/share"
BACKUP_DIR="$DOTFILE_DIR/var/backup_$(date '+%Y-%m-%d_%H-%M-%S')"

read -r -d '' __usage <<-'EOF' || true
Usage: $(basename $0) [OPTIONS...]
Installs links to dotfiles
(c) 2020 Gino Latorilla

  -h, --help        Shows this help text.
  -n, --dry-run     Show commands that will be called, but don't run them.
  -f, --force       Force creation of symbolic links.
  -u, --unlink      Replace installed links with their referrents.
EOF

function main()
{
    trap on_interrupt SIGINT
    get_options $@
    do_$task
}

function get_options()
{
    local TEMP=$(getopt -o hnfu --long help,dry-run,force,unlink -- "$@")
    if [[ $? != 0 ]]; then exit 1; fi
    eval set -- "$TEMP"

    dry_run=false
    force_link_creation=false
    task='install_links'
    while true; do
        case "$1" in
            -h | --help)
                echo "$__usage"
                exit 0;; # Tricky to see, but I should exit because no need to do anything.
            -n |--dry-run)
                dry_run=true
                shift;;
            -f | --force)
                force_link_creation=true
                shift;;
            -u | --unlink)
                task='uninstall_links'
                shift;;
            --) shift; break;;
            *) break;;
        esac
    done
}

function __run__()
{
    local command=$@
    if [ "$dry_run" = true ]; then
        echo $command
    else
        eval "$command"
    fi
}

function pretty_linker()
{
    local target="$1"
    local link="$2"
    __run__ ln --symbolic --force '"$target"' '"$link"' $3
    check "Link created: $(tput setaf 6)${link/$HOME/\~}$(tput sgr0) 🡪  ${target/$HOME/\~}"
}

function do_install_links()
{
    prepare_backup
    begin_linking

    flush_empty_backup
}

function do_uninstall_links()
{
    inform "I will remove links in your system, if I find them."

    local file
    local IFS=$(echo -en "\n\b")
    for file in $(find "$LIB_DIR"); do
        local link="$HOME/${file#$LIB_DIR/}"
        if [[ -h "$link" ]]; then
            __run__ rm '"$link"'
            __run__ cp '"$file"' '"$link"'
            check "Unlinked: $(tput setaf 6)$link$(tput sgr0)"
        fi
    done
}

function prepare_backup()
{
    __run__ mkdir -p "$BACKUP_DIR"
}

function begin_linking()
{
    inform "I will now install links in $(tput bold)$(tput setaf 2)$HOME$(tput sgr0)."

    local file
    local IFS=$(echo -en "\n\b")
    for file in $(find "$LIB_DIR" ! -type d); do
        local link="$HOME/${file#$LIB_DIR/}"
        __run__ mkdir -p $(dirname $link)
        if [[ "$(readlink -f $link)" == "$(readlink -f $file)" ]] && ! $force_link_creation; then
            warn "Skipped: ${link/$HOME/\~}"
        else
            if [[ -f "$link" ]]; then
                inform "Backup: ${link/$HOME/\~}"
                local relative_dir="$(dirname $link | grep -ov '$HOME/')"
                __run__ mkdir -p "$BACKUP_DIR/$relative_dir"
                __run__ mv '"$link"' "$BACKUP_DIR/$relative_dir"
            fi
            pretty_linker $file $link
        fi
    done
}

function flush_empty_backup()
{
    __run__ rmdir "$BACKUP_DIR" 2>/dev/null
}

function on_interrupt()
{
    warn 'You aborted this!'
    flush_empty_backup
    exit 1
}

## Do stuff
main $@
