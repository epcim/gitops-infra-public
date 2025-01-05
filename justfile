
set shell := ["bash", "-cu"]
BUILD_DIR := ".build"
TARGET := env('TARGET', 'kwok-local')
KLUCTL := env('KLUCTL_BIN', 'kluctl')
KUBECTL := env('KUBECTL_BIN', 'kubectl')

args := ""

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

kluctl-webui:
     kubectl -n kluctl-system get secret webui-secret -o jsonpath='{.data.admin-password}' | base64 -d |pbcopy &&\
     open http://localhost:8080 &\
     kubectl port-forward -n kluctl-system svc/kluctl-webui 8080:8080


# Deployment

# diff deployment changes against cluster
diff +args=args: clean_build
    {{KLUCTL}} diff -t {{TARGET}} --replace-on-error --render-output-dir {{BUILD_DIR}} {{args}}

# diff deployment changes against cluster, no no-obfuscate
diff-raw +args=args: clean_build
    {{KLUCTL}} diff -t {{TARGET}} --no-obfuscate --replace-on-error --render-output-dir {{BUILD_DIR}} {{args}}

deploy +args=args: clean_build
    {{KLUCTL}} deploy -t {{TARGET}} --replace-on-error --render-output-dir {{BUILD_DIR}} {{args}}

# @delete:
#     {{KLUCTL}} delete -t {{TARGET}}

