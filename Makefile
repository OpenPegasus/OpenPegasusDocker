# Copyright 2020 Keyport Techonologies, Inc.  All rights reserved.
# Copyright 2022 Inova Development, Inc.  All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Usage:
#
# make lint   	Lint the Dockerfile.
# make build  	Build the build image.
# make deploy   Deploy, push the build image to an image registry.
# make clean	Remove the build image from the local machine.
# Docker file for OpenPegasus WBEM Server build.  This file
# builds the docker image using Ubuntu and installs the OpenPegasus
# make file into that container.

# Currently the registry and build-image are defined to place both server
# and build containers in the same docker repository. They are named
# Registry - (username)/OpenPegasus:tag
# where the tag defines both the container type (build or server)
DOCKER_REGISTRY=kschopmeyer
BUILD_IMAGE=openpegasus-build
SHELL := /bin/bash
DOCKER_TAG := $(shell cat version.txt)

.PHONY: help
help:
	@echo "Usage:"
	@echo ""
	@echo "  make lint                  Lint the Dockerfile."
	@echo "  make build                 Build the build image."
	@echo "  make deploy                Deploy, push the build image to a docker image registry."
	@echo "  make clean	                Remove the build image from the local machine."
	@echo "  make start-build-container	Run build the pegasus server image."
	@echo ""
	@echo "  Docker file for OpenPegasus WBEM Server build.  This file"
	@echo "    builds the docker image using Ubuntu and installs the OpenPegasus"
	@echo "    makefile into that container."
	@echo ""
	@echo "Build variables"
	@echo "  Docker registry = ${DOCKER_REGISTRY}"
	@echo "  Docker image name = ${BUILD_IMAGE}"
	@echo "  Docker image version tag = ${DOCKER_TAG}"
	@echo ""
	@echo "NOTE: DOCKER_USER and DOCKER_PASSWORD are requested on deploy"
	@echo ""

.PHONY: build-build-image
build-build-image:
	@echo "Building the docker build image..."
	docker build -t ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG) .

.PHONY: publish-build-image
publish-build-image:
	@echo "Publishing the wbem server build image..."
	docker logout
	docker image tag ${DOCKER_REGISTRY}:${BUILD_IMAGE}:$(DOCKER_TAG) ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG}
	docker login -u $${DOCKER_USER} -p $${DOCKER_PASSWORD}
	docker push ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG)
	docker logout

.PHONY: clean-build-image
clean-build-image:
	@echo "Removing the build image ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG) ..."
	-docker rmi ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG)
	@echo "Removing the build image ${BUILD_IMAGE}:$(DOCKER_TAG) ..."
	-docker rmi ${BUILD_IMAGE}:$(DOCKER_TAG)

.PHONY: start-build-container
start-build-container:
	@echo start the local server container image ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG}
	sudo docker run -it --rm \
		-v /home/${USER}/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG} /bin/bash

.PHONY: run-openpegasus
run-openpegasus-image:
	@echo Example start the OpenPegasus build image to build the OpenPegasus server image..."
	sudo docker run -it --rm  -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 \
	    --log-driver=syslog --name pegasus  kschopmeyer/openpegasus-server:0.1.1 /bin/bash

lint:
	@echo "Linting Dockerfile if hadolint exists..."
	# Allow hadolint to fail or not be found
	-hadolint Dockerfile
.PHONY: lint

build: lint build-build-image
.PHONY: build

deploy: build publish-build-image
.PHONY: deploy

clean: clean-build-image
.PHONY: clean
