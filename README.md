
## Docs

This is an kluctl.io/Kustomize deployment.

## Structure


```
├── .kluctl.yml                       - kluctl.io project
├── deployment.yml                    - kluctl deployment
│
├── context.yml                       - control parameters
│
├── cluster
│   ├── apealive
│   │  	├── <namespace/app>
│   │	│   ├── kustomization.yaml
│   │	│
│   │  	├── deployment.yml
│   │  	├── context.yml               - application parameters
│   │  	├── secrets.yml               - application secrets
│   │
│   ├── context-<target>.yml          - cluster/target global parameters
│                                     
├── compose                           - reusable components
│   ├── nodeSelector
│
├── services                          - reusable application catalog (DRAFT)
│   ├── <application>
│                                     
│
├── Makefile                          - (local use only, shortcuts, optional)
├── .envrc                            - env configuration
├── .build                            - localy rendered resources
├── .repos                            - remote resources fetched/used locally
├── .tools                            - src code of tools used for deployment
├── .scripts                          - last sort of escape hell from rutines
...
```

It's:
- "Minimalist" model for lab k8s deployment
- "CLI first" with [kluctl.io](https://kluctl.io) and "CICD" later
- Leverage Kustomize, Kluctl.io, and SOPS (Helm is used only if no other option)
- In 2023 I reworked the structure to better fit [kluctl.io](https://kluctl.io)


## DISCLAIMER

- Metal bootstrap is subject to rework. I will use [tinkerbell.org](tinkerbell.org)/iPXE for the physical part. For the nodes configuration I use my [ansible repo](https://github.com/epcim/ansible-infra) as of today.
- Work in progress

## Concept and features:

- Metal bootstrap
  - network install with iPXE (http only)
  - node config management ansible/(salt)

- K8s deploy with `kluctl.io`
  - Makefile wrapper for repeated CLI operations
  - Parameter interpolation, SOPS decryption, hooks and other `kluctl.io` features.
  - Tend to use Kustomize over Helm resources
  - Tend to Helm library charts for simple deployments
  - TBD: Template gotpl/jsonent/... rendering for config delivery
  - TBD: CICD with ArgoCD/[KluctlController](https://github.com/kluctl/flux-kluctl-controller)

- Model
  - configuration is separated from the application deployment files.
  - `services` catalog of indpendently deployable services

## Usage

with make wrapper:
```sh
make help
```

with kluctl:
```
$KLUCTL --help
$KLUCTL deploy -t base --dry-run
$KLUCTL deploy -t apealive  --include-tag jellyfin --dry-run
```

edit secrets:
```
sops -i secrets.yml
```

update deployment & params:
```
$EDITOR deployment.yml context.yml .kluctl.yml
```


## Setup

Initial setup:
```sh
direnv allow .
vendir sync

# build tools
cd .tools/kluctl; go build; cd -

# unseal SOPS(AGE) encryption key
matrix decrypt -in ./.env.age.matrix -out ./.env.age
```

Git refered deployment resources can be overriden by local path:
```
# defaults in .envrc overrides to repos synced to .repos
export KLUCTL_GIT_CACHE_UPDATE_INTERVAL=1h
export KLUCTL_LOCAL_GIT_GROUP_OVERRIDE_0=github.com:epcim=${WORKSPACE:-$PWD/.repos}

```

Env:
```
direnv allow .       # to source `.envrc` variables

vendir sync          # to sync `.tools` and `.repos`
```

### Recomended OSX tools

Required:

```sh
brew install age sops jq bat direnv
brew install kluctl/tap/kluctl
brew tap vmware-tanzu/carvel && brew install vendir
```

Recommended:
```sh
# OSX, GNU first class experience
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"
brew install coreutils
brew install binutils
brew install diffutils
brew install findutils
brew install gawk
brew install grep
brew install gnu-tar
brew install gnu-sed
brew install gnu-which

brew install vendir
brew install kluctl
brew install kubectl
brew install kwok
brew install kustomize age sops jq bat direnv
go install github.com/hashicorp/go-getter/cmd/go-getter@latest
```


### Secrets

Encryption tools used:
- Mozila SOPS for all all other
  - AGE is used as encryption engine for SOPS

Configuration:
- https://github.com/mozilla/sops#22encrypting-using-age
- https://github.com/mozilla/sops#27kms-aws-profiles

Configure public key's and keys to encrypt in `.sops.yaml`

SOPS encrypt/decrypt/edit:

```sh
# encrypt all secrets across
make seal a=.

# encrypting
sops -e --in-place _secrets.yml

# editing
sops --in-place _secrets.yml

# decrypt single file
sops -d _secrets.yml
```


Use SOPS + AGE encryption:
```sh
age-keygen -o .env.age

# and append to `.sops.yaml`
```

### Long term GPG encryption of private key

Age:
```
gpg -a -r epcim@apealive.net -e .env.age
git add -f .env.age.asc
```

SealedSecrets:
```
key=.sealedsecrets-master.key
kubectl get secret -n kube-system sealed-secrets-key -o yaml >| $key

gpg -a -r epcim@apealive.net -e $key
gpg -d $key.asc # review
[[ $? ==  0 ]] && { 
  rm $key;
  git add -f $key.asc
}
```

## Debuging

```
cat .build/0/cluster/argo/.rendered.yml
```

```sh
kluctl --debug --render-output-dir .build

```



# Resources

Tools:
- https://kluctl.io
- https://kustomize.io

References:
- https://kluctl.io
- https://k8s-at-home.com/
- https://github.com/GoogleContainerTools/kpt/tree/main/package-examples/kustomize
- https://kpt.dev/faq/?id=whats-the-difference-between-kpt-and-kustomize

Tools and libraries:
- https://github.com/hashicorp/go-getter
- https://googlecontainertools.github.io/kpt/reference/fn/
- https://googlecontainertools.github.io/kpt/guides/consumer/function/


KRM Functions:
- https://console.cloud.google.com/gcr/images/kpt-fn/GLOBAL
- https://github.com/GoogleContainerTools/kpt-functions-catalog/tree/master/contrib
- https://github.com/GoogleContainerTools/kpt-functions-catalog/tree/master/functions
- https://github.com/GoogleContainerTools/kpt-functions-catalog/tree/master/examples
- https://github.com/GoogleContainerTools/kpt-functions-sdk
- ./dependencies/render-gotpl-fn

### sops

- https://catalog.kpt.dev/contrib/sops/v0.3/sops-pgp-and-age/
- https://github.com/GoogleContainerTools/kpt-functions-catalog/tree/master/contrib/functions/ts/sops


