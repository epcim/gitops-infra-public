# vim: ts=2 sw=2

# USAGE
# make help
# make a=grafana [render|deploy|show|...]


# ARGS
# 't' as kluctl.io 'target' flag
t ?= "$(ENV)"
# 's' as service, "kluctl --include-tag", if not provided it is constructed from `_`
s ?= $(shell test -e _ && realpath --relative-base "$$PWD" "_" | sed 's,service/,,')
PTH=service/$(s)



# DEFAULTS
BUILD_DIR := ./.build
KLUCTL ?= kluctl
KUBECTL ?= kubectl
KUSTOMIZE ?= kustomize
#COLORIZER_DIFF ?= bat --paging=never -pl diff
#COLORIZER_DIFF ?= colout '\|\ \+.*$$' green normal | colout '\|\ \-.*$$' red normal
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
	@$(KLUCTL) deploy -t $(t) --render-output-dir $(BUILD_DIR)

deploy-dry: workon clean_build
	$(KLUCTL) deploy -t $(t) --render-output-dir $(BUILD_DIR) --include-tag $(s) --dry-run

apply: deploy
deploy: workon clean_build
	@$(KLUCTL) deploy -t $(t) --render-output-dir $(BUILD_DIR) --include-tag $(s) --replace-on-error --yes

render: workon clean_build
	@$(KLUCTL) render -t $(t)  --render-output-dir $(BUILD_DIR) --include-tag $(s)

diff: workon
	@$(KLUCTL) diff -t $(t) --ignore-tags --ignore-labels --ignore-annotations --render-output-dir $(BUILD_DIR) --include-tag $(s) | $(COLORIZER_DIFF)

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



