## About

Infrastructure as Code (IaC) and GitOps practice deployment for `selfhosted` clusters.

This is an "Minimalist" model for lab k8s deployment kluctl.io/Kustomize and CLI first configuratin.

Inspiration:
- k8s@home team
  - https://github.com/billimek/k8s-gitops
  - https://github.com/onedr0p/home-ops
  - https://github.com/xunholy/k8s-gitops
- many others as well as my 20y of devops practice

## Structure


```
├── .kluctl.yml                       - kluctl.io project (to define target clusters and `args`)
├── deployment.yml                    - kluctl deployment root
│
├── cluster-xyz
│   ├── deployment.yml
│   ├── vars-env.yml                  - env specific vars (kube, helm, ...)
│   ├── vars-sec.yml                  - secrets (encrypted by sops)
│   ├── vars.yml                      - cluster apps configuration
│   │
├── library                           - See https://github.com/epcim/gitops-library
│   ├── service/<application>
│   ├── service-set/
│   │
├── library-set-cicd                  - an local library-set
│
├── Justfile                          - as above, just rewriten
├── .envrc                            - direnv, auto-loaded ENV
├── .build                            - tmp build/render
├── .repos                            - remote resources, vendir managed
├── .tools                            - 3'rd party repos, vendir managed
├── .scripts                          - least help when automation fails
...
```

Tools and serivces used to run infrastructure
- "CLI first" with [kluctl.io](https://kluctl.io)
- Kustomize, Kluctl.io, and SOPS (Helm is used only if noother option)
- ...


## Baremetall bootstrap

- Work in progress
- Metal bootstrap is subject to rework. I will use [tinkerbell.org](tinkerbell.org)/iPXE for the physical part. For the nodes configuration I use my [ansible repo](https://github.com/epcim/ansible-infra) as of today.

## Concept and features

- Metal bootstrap
  - network install with iPXE (http only)
  - node config management ansible/(salt)

- K8s deploy with `kluctl.io`
  - Makefile wrapper for repeated CLI operations
  - Parameter interpolation, SOPS decryption, hooks and other `kluctl.io` features.
  - Tend to use Kustomize over Helm resources
  - Tend to Helm library charts for simple deployments
  - Traefik ingress
  - TBD: Template gotpl/jsonent/... rendering for LMA config delivery
  - TBD: CICD with ArgoCD or [KluctlController](https://github.com/kluctl/flux-kluctl-controller)

- Model
  - configuration is separated from the application manifests
  - `library/<service>` catalog of deployable artefacts with example configuration

## Usage

Use `make help` or newly `just` wrappers.

Kluctl binnary directly:
```
$KLUCTL --help
$KLUCTL deploy -t kwok --dry-run
$KLUCTL deploy -t home --include-tag jellyfin --dry-run
```

Edit secrets:
```
sops -i cluster/vars-sec.yml
```


## Setup

Initial setup:
```sh
direnv allow .
vendir sync

# build tools
cd .tools/kluctl; go build; cd -

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

I leverage my https://github.com/epcim/dotfiles, for others:

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
gpg -a -r epcim@example.net -e .env.age
git add -f .env.age.asc
```

SealedSecrets:
```
key=.sealedsecrets-master.key
kubectl get secret -n kube-system sealed-secrets-key -o yaml >| $key

gpg -a -r epcim@example.net -e $key
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

# Kluctl

## Configuration options

```yaml
# include as path
# - path: ../library/traefik

# include as path, while loading vars in override order
- path: ../library/traefik
  vars:
  - file: ../library/traefik/vars.yml
    noOverride: true
  - file: ../library/traefik/vars-{{ args.env }}.yml
    ignoreMissing: true          

# include while passing all vars
  - include: ../library/metallb
    passVars: true

# include git/path with structured vars (PREFERD)
  - include: ../library/metallb
    args: {{ args }}
    vars:
    - values:
        context: {{ context_cluster.metallb }}
    when: args.bootstrap
```

## Library

`library` and `library-stack` deployemnts are best-practice configured reusable apps. (As of 2024 very fresh)

Example:
```sh
library/unifi
├── README.md
├── deploy/                       - any deployment related artefacts
├── overlays/                     - manifests and kustomize overlays
│   └── ingress-traefik.yml
├── .kluctl-library.yml           
├── deployment.yml                - kluctl deployment
├── helm-chart.yml                - dummy, interpolated from vars.yml
├── helm-values.yml               - dummy, interpolated from vars.yml
├── kustomization.yml             - dummy, interpolated from vars.yml
├── vars-example.yml              - example configuration
└── vars.yml                      - best-practice defaults
```

Additional `vars-example.yml` profiles serve as configuration examples, and possibly in future each deployment will have 
`vars-test.yml` and `vars-prod.yml` configurations.

First understand any override configuration is interpolated from vars at `cluster/vars-*.yml`.
Target environment specific values (they always differ, are expected to come as `args`, ie: ingress class or domains)

Usage, extended example:
```
  - include: ../library/minio
    args: {{ args }}
    vars:
    - values:
        context: {{ context_infra.minio }}
        secrets:
          minio: {{ secrets.minio }}
        helmChart:
          releaseName: minio-backup
        kustomize:
          namespace: infra
          resources:
            - helm-rendered.yaml
            - ./overlays/xyz.yaml
          labels:
          - includeSelectors: true
            pairs:
              instance: minio-backup
              features: backup
          replicas:
          - name: minio-backup
            count: 2
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


