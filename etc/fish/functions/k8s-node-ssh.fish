function k8s-node-ssh --description 'SSH into a Kubernetes node'
    string match -rq '^(?<userat>.+@)?(?<node>.+)$' $argv[1]
    set -l SSH_EXTRA_ARGS '-oStrictHostKeyChecking=no'
    ssh $userat$(k8s-node-ip $node) $argv[2..]
end
