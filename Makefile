#!/usr/bin/env make

# Global Vars #######################################################

CWD ?= $(or ${CURDIR},$(shell pwd))

GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

DOCKER_REGISTRY := registry-1.docker.io
DOCKER_TAG      := tzrlk/unchartedworlds-manager:${GIT_VERSION}
DOCKER_USER     ?= tzrlk
DOCKER_PASS     ?=

# Build Configuration ###############################################

.DELETE_ON_ERROR:

.DEFAULT_GOAL := docker.build

.PHONY: \
	docker.build \
	docker.login \
	docker.push \
	clean

# Friendly targets ##################################################

docker.build: .build/docker/image
docker.login: .build/docker/login
docker.push:  .build/docker/push

clean:
	rm -rf .build/

# Function Definitions ##############################################

define tag
	@mkdir -p $(dir ${1})
	$(if ${2}, \
		@echo -e "${2}" > ${1}, \
		@touch ${1})
endef

# File Targets ######################################################

## Checks to see if a particular binary is on the path.
.build/bin/%:
	$(eval BINPATH := $(shell which ${*}))
	$(if ${BINPATH}, \
		$(call tag,${@},${BINPATH}), \
		$(error '${*}' not available on path))

.build/docker/image: \
		Dockerfile
	docker build \
		--build-arg http_proxy=${http_proxy} \
		--build-arg https_proxy=${https_proxy} \
		--build-arg no_proxy=${no_proxy} \
		--tag ${DOCKER_TAG} \
		. && \
	$(call tag,${@})

.build/docker/login:
	$(if $(and ${DOCKER_USER},${DOCKER_PASS}),\
		docker login ${DOCKER_REGISTRY} \
			--username ${DOCKER_USER} \
			--password ${DOCKER_PASS} && \
		$(call tag,${@},${DOCKER_REGISTRY}${DOCKER_USER}), \
		$(error Docker registry credentials required.))

.build/docker/push: \
		.build/docker/login \
		.build/docker/image
	docker push ${DOCKER_TAG} && \
	$(call tag,${@})

