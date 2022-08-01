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

# Inherit aliases from Bash
source ~/.bash_aliases
