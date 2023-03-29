# Makefile for building a docker iamge.

# Thanks to  https://gist.github.com/mpneuried/0594963ad38e68917ef189b4e6a269db
# for a lot of this.
#
# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help build push all

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

build: ## Build the image.
	    docker build --pull --build-arg \
		  RSTUDIO_SOURCE_TAG=${RSTUDIO_SOURCE_TAG} \
		  -t ${APP_NAME} .

build-nc: ## Build the image without caching.
	    docker build --pull --no-cache --build-arg \
		  RSTUDIO_SOURCE_TAG=${RSTUDIO_SOURCE_TAG} \
		  -t ${APP_NAME} .

run: ## Run container on port configured in `config.env`
	mkdir -p ./host
	docker run -i -t --rm --env-file=./run.env -u $(UID):$(GID) \
	  -v $(PWD)/host:/host -p=$(CONTAINER_PORT):$(FORWARDING_PORT) \
	  --name="$(APP_NAME)" $(APP_NAME) $(ENTRYPOINT)

up: build run ## Run container on port configured in `config.env` (Alias to run)

stop: ## Stop and remove a running container
	docker stop $(APP_NAME); docker rm $(APP_NAME)

release: build-nc publish ## Make a release by building and publishing the `{version}` ans `latest` tagged containers to ECR

# Docker publish
publish: publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to ECR

publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):latest

publish-version: tag-version ## Publish the `{version}` taged container to ECR
	@echo 'publish $(VERSION) to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):$(TAG)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):latest

tag-version: ## Generate container `latest` tag
	@echo 'create tag $(VERSION)'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):$(TAG)
