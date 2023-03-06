# vim: ts=2 sw=2

# USAGE
# make help
# make a=grafana [render|deploy|show|...]


# ARGS
# 't' as an kluctl.io 'target' flag
t ?= "$(ENV)"
# 's' as an subpath shortcut to content, if not provaded deconstructed from ./_ file
s ?= $(shell test -e _ && realpath --relative-base "$$PWD" "_" | sed 's,service/,,')
PTH=service/$(s)



# DEFAULTS
BUILD_DIR := ./.build
KLUCTL_BIN ?= kluctl
KUBECTL_BIN ?= kubectl
KUSTOMIZE_BIN ?= kustomize
#COLORIZER_DIFF ?= bat --paging=never -pl diff
COLORIZER_DIFF ?= colout '\|\ \+.*$$' green normal | colout '\|\ \-.*$$' red normal
COLORIZER_READ ?= bat -p

.PHONY: env help render build update diff force
.DEFAULT_GOAL := deploy-dry

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -ne's/^\(.*\):\s*\(.*\)##\(.*\)/\1 @ \3/p' | column -c1 -ts "@";

workon:
	@echo "# $(PTH)"
	@ln -sTf $(PTH) _

## Kluctl shortcuts

deploy-all: clean_build
	@$(KLUCTL_BIN) deploy -t $(t) --render-output-dir $(BUILD_DIR)

deploy-dry: workon clean_build
	@$(KLUCTL_BIN) deploy -t $(t) --render-output-dir $(BUILD_DIR) -a oneshot=$(s) --dry-run | $(COLORIZER_DIFF)

apply: deploy
deploy: workon clean_build
	@$(KLUCTL_BIN) deploy -t $(t) --render-output-dir $(BUILD_DIR) -a oneshot=$(s) --replace-on-error --yes

render: workon clean_build
	@$(KLUCTL_BIN) render -t $(t)  --render-output-dir $(BUILD_DIR) -a oneshot=$(s)

diff: workon
	@$(KLUCTL_BIN) diff -t $(t) --ignore-tags --ignore-labels --ignore-annotations --render-output-dir $(BUILD_DIR) -a oneshot=$(s) | $(COLORIZER_DIFF)

show: workon render
	@find $(BUILD_DIR)/**/$(s) -name ".rendered.yml" | xargs $(COLORIZER_READ)



## Cleanup

clean: clean_build

clean_build:
	@rm -rf $(BUILD_DIR)/* || false



## Secrets

seal: seal-sops

unseal: unseal-sops

seal-sops: workon ## SOPS Encrypt all secrets path matching [_sec|secret|config|*.secret*]
	@find $(p) -path "*/secrets/*" -type f |\
		ggrep -Ev '(\.asc|\.sealed|\.matrix)' |\
		while read file; do \
		  sops -i -e $$file;\
		done;

unseal-sops: workon ## SOPS Decrypt all secrets (suffix: .enc and .enc.yaml)
	@find $(p) -path "*/secrets/*" -type f |\
		ggrep -Ev '(\.asc|\.sealed|\.matrix)' |\
		while read file; do \
		  sops -i -d $$file;\
		done;

seal-matrix:
	@echo NOT IMPLEMENTED

unsel-matrix:
	@echo NOT IMPLEMENTED



