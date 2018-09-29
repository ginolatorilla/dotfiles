set --global --export EDITOR /usr/bin/vi
set --global --export VISUAL /usr/bin/code

if [ -d ~/.local/node_modules/.bin ]
    set --global --export PATH ~/.local/node_modules/.bin $PATH
end

set --local gemdir (gem environment | string match --regex '(?<=USER INSTALLATION DIRECTORY: ).*')/bin
if [ -d "$gemdir" ]
    set --global --export PATH "$gemdir" $PATH
end

# Reuse simple aliases
source ~/.bash_aliases

# "Complex fish-only aliases"
alias cne='function _; tar -zcvO "$argv[1]" | base64 > "$argv[1].tgz64.txt"; end; _'
alias dnx='function _; base64 --decode < "$argv[1]" | tar -zxv; end; _'
alias mkcd='function _; mkdir -p $argv[1]; cd $argv[1]; end; _'
alias tgz='function _; tar -zcvf "$argv[1].tgz" "$argv[1]"; end; _'
alias whos_in_lan='function _; ping -b -w1 (ip address show | string match --regex "(?<=brd )(\d{1,3}\.?){4}(?= scope)"); arp -e; end; _'
