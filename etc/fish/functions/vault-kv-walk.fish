function vault-kv-walk --description 'Run a Vault subcommand recursively on a path'
    set -l start_path $argv[1]
    set -lx VAULT_FORMAT json

    for current_path in $(vault kv list $start_path | jq -r '.[]')
        set -l full_path $(path normalize $start_path/$current_path)

        if string match -rq '/$' $current_path
            vault-kv-walk $full_path $argv[2..]
        else
            if [ -z $argv[2..] ]
                echo $full_path
            else
                vault kv $argv[2..] $full_path
            end
        end
    end
end
