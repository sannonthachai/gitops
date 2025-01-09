## create container-pull-registry-secret

1. Go to group > Settings  > Access Tokens to create tokens with scopes "read registry" 

example: 
token name: k8s
```
$ bash docker-credentials.sh -r 192.168.12.101:5050  -u k8s -p "<TOKEN>" > docker-config.json
```

2. Create secret yaml file to apply per namespace

container-image-pull.secret.yaml
```
apiVersion: v1
kind: Secret
namespace: iden
metadata:
  name: docker-register-pull-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson:
<PUT Docker config base64 endcoded HERE>
```

3. Apply this config(container-image-pull.secret.yaml) to its namespace
```
kubectl -n iden apply -f container-image-pull.secret.yaml
```
