if grep -q WSL /proc/version
    # set --global --export DISPLAY (cat /etc/resolv.conf | grep -oP '(?<=nameserver ).+$'):0
    # set --global --export PYTHON_KEYRING_BACKEND keyring.backends.null.Keyring
    set --global --export BROWSER firefox
end

set --global --export GPG_TTY (tty)
set --global --export EDITOR (command -v vim)
set --global --export VISUAL (command -v code)' --wait'

fish_add_path $HOME/.local/bin

if command -v keychain
    eval (keychain --agents gpg,ssh --eval)
end

# Inherit aliases from Bash
source ~/.bash_aliases
