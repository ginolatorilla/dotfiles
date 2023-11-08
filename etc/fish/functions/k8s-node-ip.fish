function k8s-node-ip --description 'Gets the internal IP of a Kubernetes node'
    kubectl get node/$argv[1] --output=json | jq -r '.status.addresses | [ .[] | select(.type == "InternalIP") ][0] | .address'
end
