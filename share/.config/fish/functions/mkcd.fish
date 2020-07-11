function mkcd -d "Create a directory, then go inside it"
    if mkdir $argv
        cd $argv
    end
end
