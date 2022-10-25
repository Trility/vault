# Hashicorp Vault

## Dependencies
 - AWS EKS Cluster(https://github.com/Trility/eks)

## Required Tools
 - Terraform
 - Kubectl
 - Vault

## Helpful Tools
 - AWS CLI
 - Helm CLI

## Vault Initialize
Vault must be initialized on one of the pods - Terraform does not do this
Sharmir keys and root token should be security stored
```
kubectl --kubeconfig ~/kubeconfig-vault exec vault-0 -n vault -- vault operator init 2>&1 | tee keys
```

## Vault Features Enabled
 - Supports open source or enterprise
 - KMS Auto Unseal with Service Account permissions
 - Integrated Storage via Raft with Autopilot
 - TLS End-to-End for Raft and Listener
 - UI Enabled
 - Audit Log Storage Enabled
 - Vault Ingress via ALB

## Steps for a Production Deployment
 - Increase node instance size of cluster and pod size
 - Adjust DNS and certificates to match environment

## Helpful kubectl commands

**List everything in a namespace**
```
kubectl --kubeconfig ~/kubeconfig-vault get all -n vault
```

**View logs from a pod**
```
kubectl --kubeconfig ~/kubeconfig-vault logs vault-0 -n vault
```

**Port forward a pod**
```
kubectl --kubeconfig ~/kubeconfig-vault port-forward vault-0 8200 -n vault
```

**Login to Vault**
```
export VAULT_ADDR=https://vault.int.trility.io:8200
vault login
```

**List Vault Leader and Followers**
```
vault operator raft list-peers
```

**Enable Vault Audit Log**
```
vault audit enable file file_path=/vault/audit/vault_audit.log
```

## Links
https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide?in=vault/kubernetes
https://www.vaultproject.io/docs/platform/k8s/helm/configuration
https://github.com/hashicorp/vault-helm/blob/master/values.yaml
