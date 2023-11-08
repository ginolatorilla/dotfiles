function kubeconfig-set-token --description 'Set bearer token for the current kubeconfig context'
    if [ -z $argv[1] ]
        read -f -P 'What is the bearer token? ' token
    else
        set -f token $argv[1]
    end
    set -l ctx $(kubectl config current-context)
    set -l user $(kubectl config view -o json | jq -r ".contexts[] | select(.name == \"$ctx\") | .context.user")
    kubectl config set-credentials --token=$token $user
end
