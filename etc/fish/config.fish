set --global --export EDITOR (command -v vim)
set --global --export VISUAL (command -v code)' --wait'

set --global --export GPG_TTY (tty)

if command -q python3
    fish_add_path (python3 -c 'import os,sysconfig;print(sysconfig.get_path("scripts"))')
    fish_add_path (python3 -c 'import os,sysconfig;print(sysconfig.get_path("scripts",f"{os.name}_user"))')
end

if command -q keychain
    eval (keychain --agents gpg,ssh --eval)
end

if [ -f /opt/homebrew/bin/brew ]
    /opt/homebrew/bin/brew shellenv | source
end

if [ -d $HOME/.local/bin ]
    fish_add_path $HOME/.local/bin
end

if [ -d $HOME/.krew/bin ]
    fish_add_path $HOME/.krew/bin
end

if [ -d $HOME/go/bin ]
    fish_add_path $HOME/go/bin
end

if [ -d $HOME/.cargo/bin ]
    fish_add_path $HOME/.cargo/bin
end

if [ -d /opt/homebrew/opt/mysql-client/bin ]
    fish_add_path /opt/homebrew/opt/mysql-client/bin
end

if [ -d /opt/homebrew/Cellar/ruby/3.3.6/bin/ ]
    fish_add_path /opt/homebrew/Cellar/ruby/3.3.6/bin/
end

if [ -d $HOME/.gem/ruby/3.3.6/bin ]
    fish_add_path $HOME/.gem/ruby/3.3.6/bin
end

if [ -d $HOME/.docker/bin ]
    fish_add_path $HOME/.docker/bin
end

# Inherit aliases from Bash
source ~/.bash_aliases

starship init fish | source

# Vi mode
fish_vi_key_bindings
# Emulates vim's cursor shape behavior
# Set the normal and visual mode cursors to a block
set fish_cursor_default block
# Set the insert mode cursor to a line
set fish_cursor_insert line
# Set the replace mode cursors to an underscore
set fish_cursor_replace_one underscore
set fish_cursor_replace underscore
# Set the external cursor to a line. The external cursor appears when a command is started.
# The cursor shape takes the value of fish_cursor_default when fish_cursor_external is not specified.
set fish_cursor_external line
# The following variable can be used to configure cursor shape in
# visual mode, but due to fish_cursor_default, is redundant here
set fish_cursor_visual block
set fish_vi_force_cursor 1