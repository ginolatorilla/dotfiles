# {{ template_preamble }}

set --global --export EDITOR (command -v vim)
set --global --export VISUAL (command -v code)' --wait'

set --global --export GPG_TTY (tty)

fish_add_path $HOME/.local/bin
fish_add_path $HOME/.rd/bin

if command -v keychain
    eval (keychain --agents gpg,ssh --eval)
end

# Inherit aliases from Bash
source ~/.bash_aliases
starship init fish | source
