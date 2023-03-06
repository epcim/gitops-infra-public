
# Argo CD

Deploy:

```sh
kubectl apply -k .


# https://github.com/argoproj/argo-cd/blob/master/docs/faq.md#i-forgot-the-admin-password-how-do-i-reset-it
# bcrypt(password)
kubectl -n gitops patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

```


## Examples

- https://github.com/argoproj/argo-cd/tree/master/manifests/base
- https://github.com/kubeflow/manifests/tree/master/argo
- 
