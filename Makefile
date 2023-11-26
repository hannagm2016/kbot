.DEFAULT_GOAL := help
SHELL := /bin/bash

APP=$(shell basename $(shell git rev-parse --show-toplevel))
VERSION = $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
#APP=kbot
REGISTRY=hannabb

IMAGE_TAG=${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

ARGS1 =  $(word 1, $(MAKECMDGOALS)) # the current dist in format: linux arm64
ARGS2 =  $(word 2, $(MAKECMDGOALS)) # the current dist in format: linux arm64

TARGETOS ?= $(if $(filter apple darwin,$(ARGS1)),darwin,$(if $(filter windows,$(ARGS1)),windows,linux))
TARGETARCH ?=$(if $(filter arm arm64,$(ARGS2)),arm64,$(if $(filter amd amd64,$(ARGS2)),amd64,$(if $(filter apple darwin,$(ARGS1)),arm64,amd64)))

##@ Build
build: ## Default build for Linux amd64
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o ./kbot${EXT} -ldflags "-X=github.com/hannagm2016/kbot/cmd.appVersion=${VERSION}"

linux: build ## Build a Linux binary. [ linux [[arm|arm64] | [amd|amd64]] ] to build for the specific ARCH

apple: build ## Build a macOS binary darwin/arm64 if ARCH is not specify

windows: EXT = .exe
windows: build ## Build a Windows binary

print:
	$(info $(IMAGE_TAG))
image: ## Build container image for defaul OS/Arch [linux/amd64]
	docker build . -t ${IMAGE_TAG} --build-arg TARGETOS=${TARGETOS}

image-linux: image ## image-linux [ARCH] is an alias to linux [ARCH] image

image-apple: TARGETOS = darwin
image-apple: image ## image-apple [ARCH] is an alias to apple [ARCH] image

image-windows: TARGETOS = windows
image-windows: image ## image-windows [ARCH] is an alias to windows [ARCH] image

run:
	docker run ${IMAGE_TAG} ## Run container image

push: ## Push default container image to the REGISTRY
	docker push  ${IMAGE_TAG}

##@ Clean
clean: ## Delete build file
	rm -rf kbot

rm_container:  ## Delete all containers
	docker container rm $(shell docker ps -aq) -f

clean-image: ## Delete last created container image
	docker rmi ${IMAGE_TAG} -f

clean-all: clean clean-image ## Clean all

##@ Help
.PHONY: help

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m[ target ]\033[0m\n"} \
	/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo -e "\nYou can combine certain targets together. So, in order to push a specific image to a registry, do the following:\n\n    \033[36mmake apple arm image push\033[0m \n\nThis will build macOS binary for arm64 architecture, make image with specifc name and push it to the registry."

%::
	@true