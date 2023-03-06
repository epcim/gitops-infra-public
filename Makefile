# vim: ts=2 sw=2

# USAGE
# make help
# make i=grafana [diff|render|deploy|show|...]

# ARGS TO ENV
# SHELL := env TARGET=$(t) $(SHELL)

# ARGS
# 't' as 'kluctl --target' flag, last used is stored in `_` symlink
# 'i' as 'kluctl --include-tag', last used re-constructed  from `__`
# 'e' as 'kluctl --exclude-tag'
t ?= $(TARGET)
i ?= $(shell test -e __ && realpath --relative-base "$$PWD" "__")
e ?= 
KLUCTL_ARGS ?=
ifneq ($(strip $(i)),)
	KLUCTL_ARGS += --include-tag "$(shell basename $(i))"
endif
ifneq ($(strip $(e)),)
	KLUCTL_ARGS += --exclude-tag "$(shell basename $(e))"
endif


# DEFAULTS
BUILD_DIR := ./.build
KLUCTL ?= kluctl
KUBECTL ?= kubectl
KUSTOMIZE ?= kustomize
#COLORIZER_DIFF ?= bat --paging=never -pl diff
#COLORIZER_DIFF ?= colout '\|\ \+.*$$' green normal | colout '\|\ \-.*$$' red normal
COLORIZER_READ ?= bat -p -lyaml

.PHONY: env help render build update diff force workon
.DEFAULT_GOAL := diff

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -ne's/^\(.*\):\s*\(.*\)##\(.*\)/\1 @ \3/p' | column -c1 -ts "@";

prereq: .tools/kluctl/bin/kluctl

workon: prereq
	@echo "# $(t) $(strip $(i) $(KUBECONFIG))"
	@ln -sTf $(t) _
ifneq ($(strip $(i)),)
	@ln -sTf $(i) __
endif
ifeq ($(strip $(i)), "none")
	@unlink __
endif
	@ln -sTf cluster/$(t)/context.yml _context.yml
	@ln -sTf cluster/$(t)/secrets.yml _secrets.yml

.tools/kluctl/bin/kluctl:
	@echo "# Building kluctl"
	@cd .tools/kluctl &&\
	 go mod vendor && make build

## Kluctl shortcuts
deploy-dry: workon clean_build ## kluctl deploy --dry
	$(KLUCTL) deploy -t $(t) --dry-run $(KLUCTL_ARGS)

deploy: workon clean_build ## kluctl deploy
	$(KLUCTL) deploy -t $(t) --replace-on-error --render-output-dir $(BUILD_DIR) $(KLUCTL_ARGS)

apply: KLUCTL_ARGS += --yes # --force-apply
apply: workon deploy ## kluctl deploy --yes (no approval) 

diff: workon ## kluctl diff
	$(KLUCTL) diff -t $(t) --ignore-tags --ignore-labels --ignore-annotations --replace-on-error --force-apply --render-output-dir $(BUILD_DIR) $(KLUCTL_ARGS) # |$(COLORIZER_DIFF)

diff-full: KLUCTL_ARGS += --no-obfuscate 
diff-full: diff ## kluctl diff --no-obfuscate

diff-kube: workon diff ## kubectl diff
	@find $(BUILD_DIR)/**/$(i) -name ".rendered.yml" | xargs cat | kubectl diff -f - | $(COLORIZER_DIFF)

show: workon render ## print all manifests
	@find $(BUILD_DIR)/**/$(i) -name ".rendered.yml" | xargs $(COLORIZER_READ)



## Cleanup

clean: clean_build

clean_build:
	@rm -rf $(BUILD_DIR)/* || false



## Secrets

seal: seal-sops

unseal: unseal-sops

seal-sops: workon ## SOPS Encrypt all secrets path matching [_sec|secret|config|*.secret*]
	@find $(i) -path "*/secrets/*" -type f |\
		ggrep -Ev '(\.asc|\.sealed|\.matrix)' |\
		while read file; do \
		  sops -i -e $$file;\
		done;

unseal-sops: workon ## SOPS Decrypt all secrets (suffix: .enc and .enc.yaml)
	@find $(i) -path "*/secrets/*" -type f |\
		ggrep -Ev '(\.asc|\.sealed|\.matrix)' |\
		while read file; do \
		  sops -i -d $$file;\
		done;

seal-matrix:
	@echo NOT IMPLEMENTED

unsel-matrix:
	@echo NOT IMPLEMENTED



