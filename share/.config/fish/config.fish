if grep -q WSL /proc/version
    # set --global --export DISPLAY (cat /etc/resolv.conf | grep -oP '(?<=nameserver ).+$'):0
    # set --global --export PYTHON_KEYRING_BACKEND keyring.backends.null.Keyring
    set --global --export BROWSER firefox
    set --global --export EDITOR /usr/bin/vim.tiny
    set --global --export VISUAL "/usr/bin/code --wait"
end

set --global --export GPG_TTY (tty)

fish_add_path $HOME/.local/bin

if command -v keychain
    eval (keychain --agents gpg,ssh --eval)
end

# Linux Aliases
alias ..="cd .."
alias ...="cd ../.."
alias ..2="cd ../.."
alias ..3="cd ../../.."
alias ..4="cd ../../../.."
alias ..5="cd ../../../../.."
alias c="cat"
alias chm="chmod"
alias cho="chown"
alias cp="cp --interactive"
alias du="du --human-readable --summarize"
alias df="df --human-readable"
alias e="echo"
alias ee="echo -e"
alias en="echo -n"
alias f="find"
alias ff="find . -name"
alias ft="file --mime"
alias fr="free --giga"
alias g="grep"
alias grep="grep --perl-regexp"
alias h="help"
alias k="kill"
alias kk="kill --signal 9"
alias ka="killall"
alias l="ls"
alias la="ls --all"
alias lla="ls -l --all"
alias le="less"
alias mv="mv --interactive"
alias mkdir="mkdir --parents"
alias he="head"
alias he1="head --lines 1"
alias hn="hostname"
alias hx="hexdump"
alias p="pwd"
alias qq="quit"
alias py="python3"
alias ps="ps -a"
alias r="readlink --canonicalize"
alias rm="rm --interactive"
alias rs="rsync --progress"
alias s="sed"
alias S="sudo"
alias t="touch"
alias ta="tail"
alias ta1="tail --lines 1"
alias u="uname --all"
alias us="users"
alias v="vim.tiny"
alias w="which"
alias wg="wget"
alias xo="xdg-open"

# Apt Aliases
alias sai="sudo apt install"
alias sau="sudo apt update"
alias sap="sudo apt purge"

# Git Aliases
alias ga="git add"
alias gb="git branch"
alias gbi="git bisect"
alias gc="git clone"
alias gcl="git clean -ffxd"
alias gci="git commit"
alias gco="git checkout"
alias gd="git diff"
alias gf="git fetch"
alias gl="git log"
alias gll="git log --oneline --graph --decorate"
alias gp="git pull --ff-only"
alias gpr="git pull --rebase"
alias gpu="git push --set-upstream origin"
alias gr="git remove"
alias grs="git reset"
alias grb="git rebase --interactive"
alias grv="git revert"
alias gs="git status"
alias gsh="git show"
alias gss="git status --short --branch"

# Docker Aliases
alias dri="docker run -Pit"
alias di="docker images"
alias dps="docker ps -a"
alias drm="docker rm"
alias dex="docker exec"
alias dci="docker commit"
