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
.PHONY: help build build-nc run up stop release publish publish-branch \
    publish-latest publish-short-hash publish-version tag tag-branch \
	tag-latest tag-short-hash tag-version docker-clean 

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
# Build on a mac - Ref:
build: ## Build the image. If building on a mac, check out docs for that.
		./create-builder-image.sh
	    docker build --platform=linux/amd64 --progress=plain --build-arg \
		  RSTUDIO_SOURCE_TAG=${RSTUDIO_SOURCE_TAG} \
		  -t ${APP_NAME} .

build-nc: ## Build the image without caching.
		./create-builder-image.sh
	    docker build --no-cache --platform=linux/amd64 --progress=plain --build-arg \
		  RSTUDIO_SOURCE_TAG=${RSTUDIO_SOURCE_TAG} \
		  -t ${APP_NAME} .

run: ## Run container on port configured in `config.env`
	mkdir -p ./host
	docker run -i -t --rm --env-file=./run.env -u $(UID):$(GID) \
	  -v $(PWD)/host:/host -p=$(FORWARDING_PORT):$(CONTAINER_PORT) \
	  --name="$(APP_NAME)" $(APP_NAME) $(ENTRYPOINT)

up: build run ## Run container on port configured in `config.env` (Alias to run)

stop: ## Stop and remove a running container
	docker stop $(APP_NAME); docker rm $(APP_NAME)

release: build-nc publish ## Make a release by building and publishing the `{version}` ans `latest` tagged containers to ECR

# Docker publish
publish: publish-latest publish-branch publish-short-hash ## Publish tags
	@echo 'publish tags latest $(TAG) $(COMMIT_HASH) to $(IMAGE_REPO)'

publish-latest: tag-latest ## Publish the `latest` tagged container to ECR
	@echo 'publish latest to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):latest

publish-branch: tag-branch ## Publish the `{CURRENT_BRANCH}` tagged container to ECR
	@echo 'publish $(CURRENT_BRANCH) to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):$(CURRENT_BRANCH)

publish-short-hash: tag-short-hash ## Publish the short-hash tagged container to ECR
	@echo 'publish $(COMMIT_HASH) to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):$(COMMIT_HASH)

publish-version: tag-version ## Publish the `{VERSION}` tagged container to ECR
	@echo 'publish $(VERSION) to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):$(VERSION)

# Docker tagging
tag: tag-latest tag-branch tag-short-hash ## Generate container tags

tag-latest: ## Generate container `latest` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):latest

tag-branch: ## Generate container `{CURRENT_BRANCH}` tag
	@echo 'create tag $(CURRENT_BRANCH)'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):$(CURRENT_BRANCH)

tag-short-hash: ## Generate container short-hash tag created from last commit or current datetime if tree is dirty
	@echo 'create tag $(COMMIT_HASH)'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):$(COMMIT_HASH)

tag-version: ## Generate container `{VERSION}` tag
	@echo 'create tag $(VERSION)'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):$(VERSION)

docker-clean: ## Prune unused images, containers, and networks from the local Docker system.
	docker system prune -f
