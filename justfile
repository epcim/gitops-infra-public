set shell := ["bash", "-cu"]
BUILD_DIR := ".build"
KLUCTL := env('KLUCTL_BIN', 'kluctl')
KUBECTL := env('KUBECTL_BIN', 'kubectl')
TARGET := env('TARGET', 'kwok-local')

include := ""
exclude := ""
args := if include != "" { " --include-tag " + include } else \
        if exclude != "" { " --exclude-tag " + exclude } else { "" }

_default:
    @just --list --unsorted

# Inspect
show file=".rendered" :
    find {{BUILD_DIR}} -name "{{file}}*" | tee -a /dev/stderr | xargs bat -p -lyaml 

show-kinds kinds="" file=".rendered":
    find {{BUILD_DIR}} -name "{{file}}*" | tee -a /dev/stderr | xargs yq 'select(.kind|match("{{kinds}}"))' | bat -p -lyaml 

# Repo
clean:
    just clean_build

clean_build:
	rm -rf {{BUILD_DIR}}/* || false

# Shortcuts

kluctl action="get" args="":
    kubectl {{action}} KluctlDeployment -n kluctl-system {{args}}

kluctl-webui:
     kubectl -n kluctl-system get secret webui-secret -o jsonpath='{.data.admin-password}' | base64 -d |pbcopy &&\
     open http://localhost:8080 &\
     kubectl port-forward -n kluctl-system svc/kluctl-webui 8080:8080


# Deployment

# diff deployment changes against cluster
diff +args=args: clean_build
    {{KLUCTL}} diff -t {{TARGET}} --ignore-kluctl-metadata --replace-on-error --render-output-dir {{BUILD_DIR}} {{args}}

# diff deployment changes against cluster, no no-obfuscate
diff-raw +args=args: clean_build
    {{KLUCTL}} diff -t {{TARGET}} --ignore-kluctl-metadata --no-obfuscate --replace-on-error --render-output-dir {{BUILD_DIR}} {{args}}

@deploy +args=args:
    [[ args =~ "=" ]] && just {{args}} apply ||\
                         just include={{args}} apply

# build and apply with y/n
apply +args=args: clean_build
    {{KLUCTL}} deploy -t {{TARGET}} --replace-on-error --render-output-dir {{BUILD_DIR}} {{args}}


# @delete:
#     {{KLUCTL}} delete -t {{TARGET}}

