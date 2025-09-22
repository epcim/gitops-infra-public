set shell := ["bash", "-cu"]
set export := true
set dotenv-load := true
set positional-arguments
ROOT_DIR := source_dir()
BUILD_DIR := source_dir()+"/.build"
KLUCTL := env('KLUCTL_BIN', 'kluctl')
KUBECTL := env('KUBECTL_BIN', 'kubectl')
#KUBECONFIG := env('KUBECONFIG', '')
TARGET := env('TARGET', 'kwok-local')

in := ""
ex := ""
flags := if in != "" { " --include-tag " + in } else \
         if ex != "" { " --exclude-tag " + ex } else { "" }

_default:
  @just --list --unsorted

[group('misc')]
[confirm("Do you want to continue?")]
ask_continue:

[group('misc')]
@ask_message q:
    echo "{{q}} [y/N]"
    read REP && [[ "$REP" =~ ^[Yy]$ ]]

# ask for y/n
[group('misc')]
@ask q:
    echo ""
    echo "{{q}} [y/N]"
    read REP && [[ "$REP" =~ ^[Yy]$ ]]

# Clean all cache
[group('misc')]
clean:
    just clean_build

# Clean the build directory
[group('misc')]
clean_build:
	rm -rf {{BUILD_DIR}}/* || false


# Scan repo for leaked secrets
[group('misc')]
scan-secrets PTH="":
    gitleaks git -v $PTH &&\
    trufflehog filesystem $PTH

# Shortcuts
# open kluctl-webui
[group('shortcut')]
kluctl-webui:
     kubectl -n kluctl-system get secret webui-secret -o jsonpath='{.data.admin-password}' | base64 -d |pbcopy &&\
     open http://localhost:8081 &\
     kubectl port-forward -n kluctl-system svc/kluctl-webui 8081:8080

# open grafana.env-monitor 
[group('shortcut')]
env-grafana:
    sops -d vars-sec.yml | yq '.secrets.grafana.adminPassword' -r | base64 -d |pbcopy && \
     sleep 3 && open "http://localhost:8280/d/a7e130cb82be229d6f3edbfd0a438001/loki-logs?orgId=1&from=now-1h&to=now&timezone=utc&var-datasource=mimir-prometheus&var-cluster=dev1&var-namespace=env-monitor-loki&var-loki_datasource=loki&var-container=compactor&var-level=debug&var-level=info&var-level=warn&var-level=error&var-filter=&refresh=10s" &\
     kubectl port-forward -n env-monitor svc/grafana 8280:80



# argocd port forward
[group('shortcut')]
argocd-port-forward:
    {{KUBECTL}} port-forward -n argo svc/argocd-server 8080:80

# Deployment
# CRUD actions with KluctlDeployment Kind
[group('shortcut')]
kluctl action="get" args="":
    kubectl {{action}} KluctlDeployment -n kluctl-system {{flags}} {{args}}

# Wraps `kluctl deploy` for single component as include tag. (Shorter diff, Asks y/n, Runs "just apply {{args}} --yes")
[group('deployment')]
@deploy itag="" +args="": clean
   [[ "$itag" =~ "--" ]] && args="$itag $args" && itag="";\
   [[ "$itag" != ""   ]] && args="--include-tag $itag $args";\
   just in={{in}} ex={{ex}} diff $args && just ask_continue && just in={{in}} ex={{ex}} apply $args --short-output --yes


# Wraps `kluctl deploy`
[group('deployment')]
apply +args="":
    {{KLUCTL}} deploy -t {{TARGET}} --replace-on-error --render-output-dir {{BUILD_DIR}} {{flags}} {{args}}

# Wraps `kluctl delete`
[group('deployment')]
delete +args="":
    {{KLUCTL}} delete -t {{TARGET}} {{args}}

# Wraps `kluctl diff` deployment changes against cluster
[group('review')]
diff +args="": clean_build
    {{KLUCTL}} diff -t {{TARGET}} --ignore-kluctl-metadata --replace-on-error --render-output-dir {{BUILD_DIR}} {{flags}} {{args}}

# Wraps `kluctl diff` deployment changes against cluster, no no-obfuscate
[group('review')]
diff-raw +args="": clean_build
    {{KLUCTL}} diff -t {{TARGET}} --ignore-kluctl-metadata --no-obfuscate --replace-on-error --render-output-dir {{BUILD_DIR}} {{flags}} {{args}}

# Inspect rendered output
[group('review')]
show file=".rendered" :
    find {{BUILD_DIR}} -name "{{file}}*" | tee -a /dev/stderr | xargs bat -p -lyaml 

# Inspect only specific Kinds from rendered output
[group('review')]
show-kinds kinds="" file=".rendered":
    find {{BUILD_DIR}} -name "{{file}}*" | tee -a /dev/stderr | xargs yq 'select(.kind|match("{{kinds}}"))' | bat -p -lyaml 



# @delete:
#     {{KLUCTL}} delete -t {{TARGET}}

### IN PROGRESS / IDEAS
ops-kubeconfig SERVER="10.10.1.15":
  ssh ops@{{SERVER}} microk8s.config > $KUBECONFIG

# Etcd ops
[group('etcd')]
@etcd-show-members arg1:
    {{KUBECTL}} exec -it -n {{arg1}} sts/etcd -c etcd -- etcdctl endpoint status --cluster -w table
    {{KUBECTL}} exec -it -n {{arg1}} sts/etcd -c etcd -- etcdctl endpoint health --cluster -w table
    {{KUBECTL}} exec -it -n {{arg1}} sts/etcd -c etcd -- etcdctl member list -w table


