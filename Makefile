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

REGISTRY=openpegasus
BUILD_IMAGE=wbemserver-build
SHELL := /bin/bash
TAG := $(shell cat version.txt)

.PHONY: help
help:
	@echo "Usage:"
	@echo ""
	@echo "  make lint     Lint the Dockerfile."
	@echo "  make build    Build the build image."
	@echo "  make deploy   Deploy, push the build image to an image registry."
	@echo "  make clean	Remove the build image from the local machine."
	@echo "  Docker file for OpenPegasus WBEM Server build.  This file"
	@echo "    builds the docker image using Ubuntu and installs the OpenPegasus"
	@echo "    makefile into that container."
	@echo ""
	@echo "Build variables"
	@echo "  Docker registry = ${REGISTRY}"
	@echo "  Docker image name = ${BUILD_IMAGE}"
	@echo "  Docker image version tag = ${TAG}"
	@echo ""
	@echo "NOTE: DOCKER_USER and DOCKER_PASSWORD are requested on deploy"
	@echo ""

build-build-image:
	@echo "Building the docker build image ${REGISTRY}/${BUILD_IMAGE}:$(TAG) ..."
	docker build -t ${REGISTRY}/${BUILD_IMAGE}:$(TAG) .
.PHONY: build-build-image

publish-build-image:
	@echo "Publishing the wbem server build image ${REGISTRY}/${BUILD_IMAGE}:$(TAG) ..."
	docker logout
	docker login -u $${DOCKER_USER} -p $${DOCKER_PASSWORD}
	docker push ${REGISTRY}/${BUILD_IMAGE}:$(TAG)
	docker logout
.PHONY: publish-build-image

clean-build-image:
	@echo "Removing the build image ${REGISTRY}/${BUILD_IMAGE}:$(TAG) ..."
	docker rmi ${REGISTRY}/${BUILD_IMAGE}:$(TAG)
.PHONY: clean-build-image

build-openpegasus:
	@echo start the local server container image $BUILD_IMAGE:$TAG
	sudo docker run -it --rm \
		-v /home/$USER/.ssh:/root/.ssh \
		-v /var/run/docker.sock:/var/run/docker.sock $BUILD_IMAGE:$TAG /bin/bash

lint:
	@echo "Linting Dockerfile if hadolint exists..."
	-hadolint Dockerfile
.PHONY: lint

build: lint build-build-image
.PHONY: build

# Start the server image to download and build OpenPegasus
build-pegasus: build-openpegasus
.PHONEY: build-pegasus

deploy: build publish-build-image
.PHONY: deploy

clean: clean-build-image
.PHONY: clean
