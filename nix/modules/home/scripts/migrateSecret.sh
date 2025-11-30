kubectl get secret $5 -n $3 --context $1 -o yaml | sed "s/namespace: .*/namespace: $4/" | kubectl apply --context $2 -f -
