set --global --export EDITOR (command -v vim)
set --global --export VISUAL (command -v code)' --wait'

set --global --export GPG_TTY (tty)

fish_add_path $HOME/.local/bin
fish_add_path $HOME/.rd/bin

if command -q python3
    fish_add_path (python3 -c 'import os,sysconfig;print(sysconfig.get_path("scripts",f"{os.name}_user"))')
end

if command -q keychain
    eval (keychain --agents gpg,ssh --eval)
end

# Inherit aliases from Bash
source ~/.bash_aliases
starship init fish | source
