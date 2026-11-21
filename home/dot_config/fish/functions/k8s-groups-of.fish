function k8s-groups-of --description 'List all groups of a user'
    kubectl get groups -o json $argv[2..] \
        | jq -r "\
            .items[]
            | select(
                [.users[]] | contains([\"$argv[1]\"])
                )
            | .metadata.name
            "
end
