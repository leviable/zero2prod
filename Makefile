SHELL := /bin/bash -euo pipefail 

MAKEFILE_PATH := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

REGISTRY := ghcr.io/leviable
REPO:= zero2prod
REVISION := $(shell git rev-parse --short=8 HEAD)
BRANCH_NAME := $(shell git rev-parse --abbrev-ref HEAD)
BRANCH_REVISION := $(subst /,-,$(BRANCH_NAME))-${REVISION}
GIT_TAG := $(shell git describe --tags --exact-match $(REVISION) 2>/dev/null)

IMAGE := $(REGISTRY)/$(REPO):$(BRANCH_REVISION)
IMAGE_BUILDER := $(REGISTRY)/$(REPO):$(BRANCH_REVISION)-builder
IMAGE_TAG := $(REGISTRY)/$(REPO):$(GIT_TAG)
IMAGE_LATEST := $(REGISTRY)/$(REPO):latest
IMAGE_BUILDER_LATEST := $(REGISTRY)/$(REPO):latest-builder

OS := $(shell uname)

print-info:
	@echo "OS:              $(OS)"
	@echo "REVISION:        $(REVISION)"
	@echo "BRANCH_NAME:     $(BRANCH_NAME)"
	@echo "BRANCH_REVISION: $(BRANCH_REVISION)"
	@echo "GIT_TAG:         $(GIT_TAG)"
	@echo "IMAGE:           $(IMAGE)"
	@echo "IMAGE_BUILDER:   $(IMAGE_BUILDER)"
	@echo "IMAGE_TAG:       $(IMAGE_TAG)"
	@echo "IMAGE_BRANCH:    $(IMAGE_BRANCH)"

.PHONY: _app
_app: 
	docker build \
		--build-arg REPO=$(REPO) \
		--build-arg REVISION=$(REVISION) \
		--cache-from $(IMAGE) \
		--cache-from $(IMAGE_BUILDER) \
		--cache-from $(IMAGE_LATEST) \
		--cache-from $(IMAGE_BUILDER_LATEST) \
		--target app \
		-t $(IMAGE) \
		-f ./Dockerfile .

.PHONY: _builder
_builder: 
	docker build \
		--build-arg REPO=$(REPO) \
		--build-arg REVISION=$(REVISION) \
		--cache-from $(IMAGE) \
		--cache-from $(IMAGE_BUILDER) \
		--cache-from $(IMAGE_LATEST) \
		--cache-from $(IMAGE_BUILDER_LATEST) \
		--target builder \
		-t $(IMAGE_BUILDER) \
		-f ./Dockerfile .

.PHONY: build
build: _builder _app

.PHONY: push
push:
	docker push $(IMAGE)

.PHONY: pull
pull:
	docker pull $(IMAGE)

.PHONY: tag-latest
tag-latest:
	docker tag $(IMAGE) $(IMAGE_LATEST)
	docker tag $(IMAGE_BUILDER) $(IMAGE_BUILDER_LATEST) || true

.PHONY: push-latest
push-latest:
	docker push $(IMAGE_LATEST)
	docker push $(IMAGE_BUILDER_LATEST) || true

.PHONY: pull-latest
pull-latest:
	docker pull $(IMAGE_LATEST)
	docker pull $(IMAGE_BUILDER_LATEST) || true

.PHONY: docker-login
docker-login:
	echo $$GHCR_PAT | docker login -u leviable --password-stdin ghcr.io
