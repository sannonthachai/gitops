# gitops



## Install Argo CD
- k apply -k base/argo-cd

## Binding Gitops Repository
- config secret in base/argo-cd/secrets.yaml
- k apply -f base/argo-cd/secrets.yaml

## Apply Argo CD Applications
- If not set notification token -> comment secrets in overlay/argo-cd/kustomization.yaml
- k apply -f base/argo-cd/applications.yaml
