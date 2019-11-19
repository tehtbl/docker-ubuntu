# Shell to use
SHELL := /bin/bash

# The directory of this file
MY_DIR := $(shell echo $(shell cd "$(shell  dirname "${BASH_SOURCE[0]}" )" && pwd ))

# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= env.config
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# import deploy config
# You can change the default deploy config with `make dpl="deploy_special.env" release`
dpl ?= env.deploy
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
# based on: https://stackoverflow.com/questions/10858261/abort-makefile-if-variable-not-set
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

# grep the version from the mix file
# VERSION=$(shell ./version.sh)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# DOCKER TASKS
# Build the container
build: ## Build the container
	@:$(call check_defined, APP_NAME, container name)
	@:$(call check_defined, BUILD_DIST, container name)
	@:$(call check_defined, NAMESPACE_USER, docker namespace username)
	docker build --build-arg BUILD_DIST=$(BUILD_DIST) -t $(NAMESPACE_USER)/$(APP_NAME) .

build-nc: ## Build the container without caching
	@:$(call check_defined, APP_NAME, container name)
	@:$(call check_defined, BUILD_DIST, container name)
	@:$(call check_defined, NAMESPACE_USER, docker namespace username)
	docker build --no-cache --build-arg BUILD_DIST=$(BUILD_DIST) -t $(NAMESPACE_USER)/$(APP_NAME) .

run: ## Run container on port configured in `env.config`
	@:$(call check_defined, APP_NAME, container name)
	@:$(call check_defined, BUILD_DIST, container name)
	@:$(call check_defined, NAMESPACE_USER, docker namespace username)
	docker run -it --rm \
	 --privileged \
	 --volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
	 --env-file=$(MY_DIR)/env.config \
	 --name="$(APP_NAME)" \
	 $(NAMESPACE_USER)/$(APP_NAME)

up: build run ## Run container on port configured in `config.env` (Alias to run)

stop: ## Stop and remove a running container
	@:$(call check_defined, APP_NAME, container name)
	docker stop $(APP_NAME); docker rm $(APP_NAME)




release: build-nc publish ## Make a release by building and publishing the `{version}` and `latest` tagged containers to hub

# Docker publish
publish: publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to hub

publish-latest: tag-latest ## Publish the `latest` taged container to hub
	@:$(call check_defined, APP_NAME, container name)
	@:$(call check_defined, NAMESPACE_USER, docker namespace username)
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(NAMESPACE_USER)/$(APP_NAME):latest

publish-version: tag-version ## Publish the `{version}` tagged container to hub
	@:$(call check_defined, APP_NAME, container name)
	@:$(call check_defined, BUILD_DIST, container name)
	@:$(call check_defined, NAMESPACE_USER, docker namespace username)
	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
	docker push $(NAMESPACE_USER)/$(APP_NAME):$(BUILD_DIST)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` and `latest` tags

tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	@:$(call check_defined, APP_NAME, container name)
	@:$(call check_defined, NAMESPACE_USER, docker namespace username)
	docker tag $(NAMESPACE_USER)/$(APP_NAME) $(NAMESPACE_USER)/$(APP_NAME):latest

tag-version: ## Generate container `latest` tag
	@:$(call check_defined, APP_NAME, container name)
	@:$(call check_defined, BUILD_DIST, container name)
	@:$(call check_defined, NAMESPACE_USER, docker namespace username)
	@echo 'create tag $(VERSION)'
	docker tag $(NAMESPACE_USER)/$(APP_NAME) $(NAMESPACE_USER)/$(APP_NAME):$(BUILD_DIST)


version: ## Output the current version
	@:$(call check_defined, BUILD_DIST, container name)
	@echo $(BUILD_DIST)
