
# My GIT-OPS INFRA

- Its "Minimalist" model for k8s deployment & operation

- Its "CLI first" and "CICD" later

- Its based on Kustomize + Kluctl.io and KRM Functions

- IN PROGRESS: `services` are to some extent share-able for different deployments under `targets`

- In 2023 I reworked the structure to better fit [kluctl.io](https://kluctl.io) which best fits all
  my needs identified in past few years. More on its features here [kluctl.io/blog](https://kluctl.io/blog/).

## DISCLAIMER

As of `2023/03` there are still manny things in-progress or in re-design. Even though I use the private copy of this repo
daily on my deployments. Main structure wont change, but I will move all target specific logic under target directory
and free this way `services` directory to be more re-usable. 

Independent configuration of services is not implemented at all.

Metal bootstrap is subject to rework. I will use [tinkerbell.org](tinkerbell.org)/iPXE for the physical part.
For the nodes I use today this [ansible repo](https://github.com/epcim/ansible-infra).

## Concept and features:

- Metal bootstrap
  - iPXE/PXE with http, tftpd
  - ansible config management

- K8s deploy with `kluctl.io` or `kubectl` builtin Kustomize
  - Integrated secret encryption with SOPS
  - Interpolation and hooks based on `kluctl.io` features
  - Tend to use mostly Kustomize resources
  - Tend to Helm library charts before regular helm charts
  - TO REWORK: Full CICD with ArgoCD/Flux/[KluctlController](https://github.com/kluctl/flux-kluctl-controller)
  - Makefile wrapper

- Model
  - `services` can be deployed independently
  - `services` can be shared many times with overrides under `targets`
  - configuration is separated from the application deployment files.
  - Prometheus kube stack/Grafana/Thanos

POSTPONED:
- KRM Functions
  - for (helm, gotpl, jsonnet) rendering
- Monitoring
  - Jsonnet configuration for monitoring resources

## Structure

```
├── compose                           - reusable components, overlays
│
├── serivce                           - app manifests
│   ├── deployment.yml                - Kluctl.io sub/deployment
│   ├── restic
│   │   ├── configs
│   │   ├── secrets
│   │   ├── overlays
│   │   ├── kustomization.yaml
│
├── targets
│   ├── base
│   ├── lab1
│   │   ├── deployment.yml            - Kluctl.io sub/deployment
│   │   ├── <namespace>
│   │   │   ├── <app instance>
│
├── .envrc                            - env configuration
├── .kluctl.yml                       - Kluctl.io project
├── deployment.yml                    - Kluctl.io deployment targets
├── context.yml -> <target>/<name>/   - parameters
├── secrets.yml -> <target>/<name>/   - secrets (SOPS encrypted)
│
├── Makefile                          - (local use only, shortcuts, optional)
├── .scripts                          - last sort of escape hell from rutines
├── .build                            - localy rendered resources
├── .repos                            - remote resources fetched/used locally
├── .tools                            - src code of tools used for deployment
...

```

Note: For single cluster deployment you may want instead `targets/<name>` use just `cluster`.

Note: All cluster related configuration goes under `targets`



## Setup

Can varry, his is what I use on OSX:
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
brew install kustomize age sops jq bat direnv
go install github.com/hashicorp/go-getter/cmd/go-getter@latest
```

Sync
```
direnv allow .       # to source `.envrc` variables

vendir sync          # to sync `.tools` and `.repos`
```

And prepare `age` & `gpg` structure in repo as described in section "Secrets"



## Usage (kluctl)

With Makefile shortcut:
```sh
make help

# specify target (as an layer)
make t=base
make apply

# target set as $ENV and s= specify an single-shot service as kluctl --include-tag
make s=jellyfin
make make apply
make [render|diff|deploy|...]
```

With pure kluctl:
```
kluctl deploy -t "base" --dry-run
kluctl deploy -t "apealive"  --include-tag jellyfin --dry-run
```

## Usage (with kubectl)

Some deployements are still based on pure Kustomize and KRM or internal HelmChart inflation pluging.
These can be still used similar way:

```
make -f Makefile.kustomize render s=syncthing

# which calls sth like
kubectl kustomize --enable-alpha-plugins --load-restrictor LoadRestrictionsNone --network  service/syncthing
```


## Secrets

Encryption tools used:
- SealedSecrets, prefered for kube secrets
- Mozila SOPS for all all other
  - AGE is used as encryption engine for SOPS

Docs:
- https://github.com/mozilla/sops#22encrypting-using-age
- https://github.com/mozilla/sops#27kms-aws-profiles


### AGE setup:

```sh
age-keygen -o .${ENV}.age

gpg -a -r epcim@apealive.net -e .${ENV}.age
git add -f .${ENV}.age.asc
```

### SOPS setup:

```sh
# configure AGE public key in .sops.yaml
vim .sops.yaml
```

### SealedSecrets setup: (DEPRECATED)

backup master key:

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

### Shortcuts

SOPS encrypt/decrypt:

```sh
# decrypt all secrets (with *.enc.* suffix)
make unseal a=.

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


