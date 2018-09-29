if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

if [ -d "$HOME/.local/node_modules/.bin" ] ; then
    PATH="$HOME/.local/node_modules/.bin:$PATH"
fi

if [ -d "$(gem environment | grep -oP '(?<=USER INSTALLATION DIRECTORY: ).*')/bin" ] ; then
    PATH="$(gem environment | grep -oP '(?<=USER INSTALLATION DIRECTORY: ).*')/bin:$PATH"
fi

export PATH

# set PATH so it includes user's private bin directories
export EDITOR='/usr/bin/vi'
export VISUAL='/usr/bin/code'

# "Complex aliases"
alias tgz='_(){ tar -zcvf $1.tgz $*"; }; _'
alias mkcd='_(){ mkdir -p "$*"; cd "$*"; }; _'
alias srr='_(){ svn revert -R .; svn st --ignore-externals | grep "^?" | cut -c9- | xargs rm -rf; svn cleanup . }; _'
