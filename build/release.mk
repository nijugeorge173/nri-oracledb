BUILD_DIR    := ./bin/
GORELEASER_VERSION := v0.174.1
GORELEASER_BIN ?= bin/goreleaser

bin:
	@mkdir -p $(BUILD_DIR)

$(GORELEASER_BIN): bin
	@echo "===> $(INTEGRATION) === [$(GORELEASER_BIN)] Installing goreleaser $(GORELEASER_VERSION)"
	@(wget -qO /tmp/goreleaser.tar.gz https://github.com/goreleaser/goreleaser/releases/download/$(GORELEASER_VERSION)/goreleaser_$(OS_DOWNLOAD)_x86_64.tar.gz)
	@(tar -xf  /tmp/goreleaser.tar.gz -C bin/)
	@(rm -f /tmp/goreleaser.tar.gz)
	@echo "===> $(INTEGRATION) === [$(GORELEASER_BIN)] goreleaser downloaded"

.PHONY : release/clean
release/clean:
	@echo "===> $(INTEGRATION) === [release/clean] remove build metadata files"
	rm -fv $(CURDIR)/src/versioninfo.json
	rm -fv $(CURDIR)/src/resource.syso

.PHONY : release/deps
release/deps: $(GORELEASER_BIN)
	@echo "===> $(INTEGRATION) === [release/deps] install goversioninfo"
	@GO111MODULE=off go get github.com/josephspurrier/goversioninfo/cmd/goversioninfo

.PHONY : release/build
release/build: release/deps release/clean
ifeq ($(PRERELEASE), true)
	@echo "===> $(INTEGRATION) === [release/build] PRE-RELEASE compiling all binaries, creating packages, archives"
	@$(GORELEASER_BIN) release --config $(CURDIR)/build/.goreleaser.yml --rm-dist
else
	@echo "===> $(INTEGRATION) === [release/build] build compiling all binaries"
	@$(GORELEASER_BIN) build --config $(CURDIR)/build/.goreleaser.yml --snapshot --rm-dist
endif

.PHONY : release/fix-archive
release/fix-archive:
	@echo "===> $(INTEGRATION) === [release/fix-archive] fixing tar.gz archives internal structure"
	@bash $(CURDIR)/build/nix/fix_archives.sh $(CURDIR)

.PHONY : release/sign/nix
release/sign/nix:
	@echo "===> $(INTEGRATION) === [release/sign] signing packages"
	@bash $(CURDIR)/build/nix/sign.sh


.PHONY : release/publish
release/publish:
	@echo "===> $(INTEGRATION) === [release/publish] publishing artifacts"
	@bash $(CURDIR)/build/upload_artifacts_gh.sh

.PHONY : release
release: release/build release/fix-archive release/sign/nix release/publish release/clean
	@echo "===> $(INTEGRATION) === [release/publish] full pre-release cycle complete for nix"

OS := $(shell uname -s)
ifeq ($(OS), Darwin)
	OS_DOWNLOAD := "darwin"
	TAR := gtar
else
	OS_DOWNLOAD := "linux"
endif
