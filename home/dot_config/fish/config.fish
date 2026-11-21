# Put Homebrew on PATH first, because the next lines use tools from it.
# Homebrew is in /opt/homebrew on macOS and in /home/linuxbrew/.linuxbrew on Linux.
for brew_prefix in /opt/homebrew /home/linuxbrew/.linuxbrew
    if test -x $brew_prefix/bin/brew
        $brew_prefix/bin/brew shellenv | source
        break
    end
end
set --erase brew_prefix

set --global --export EDITOR (command -v nvim)
set --global --export GPG_TTY (tty)

# Keep the k9s and lazygit configs in ~/.config on macOS too.
set --global --export K9S_CONFIG_DIR $HOME/.config/k9s
set --global --export LG_CONFIG_FILE $HOME/.config/lazygit/config.yml

if command -q python3
    fish_add_path (python3 -c 'import os,sysconfig;print(sysconfig.get_path("scripts"))')
    fish_add_path (python3 -c 'import os,sysconfig;print(sysconfig.get_path("scripts",f"{os.name}_user"))')
end

# On Linux, keychain starts one ssh-agent for all shells. It loads no keys:
# ssh adds each key on first use (AddKeysToAgent in ~/.ssh/config). GnuPG
# starts gpg-agent itself. keychain 3 ignores --agents and prints a warning.
if command -q keychain; and begin
        status is-interactive; or status is-login
    end
    eval "$(keychain add --eval --quiet --noask)"
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

if set --query HOMEBREW_PREFIX; and [ -d $HOMEBREW_PREFIX/opt/mysql-client/bin ]
    fish_add_path $HOMEBREW_PREFIX/opt/mysql-client/bin
end

if [ -d $HOME/.docker/bin ]
    fish_add_path $HOME/.docker/bin
end

# Inherit aliases from Bash
source ~/.bash_aliases

for plugin in starship zoxide atuin
    if command -q $plugin
        $plugin init fish | source
    end
end

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

# Local overrides (not managed by dotfiles)
if test -f "$__fish_config_dir/config.fish.local"
    source "$__fish_config_dir/config.fish.local"
end
# lean-ctx shell hook — begin
if test -f "$HOME/.config/lean-ctx/shell-hook.fish"
    source "$HOME/.config/lean-ctx/shell-hook.fish"
end
# lean-ctx shell hook — end
