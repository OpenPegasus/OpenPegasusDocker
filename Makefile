# Copyright 2020 Keyport Techonologies, Inc.  All rights reserved.
# Copyright 2020 Inova Development, Inc.  All rights reserved.
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
#

REGISTRY=openpegasus

BUILD_IMAGE=wbem-build

SHELL := /bin/bash

TAG := $(shell cat version.txt)


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

lint:
	@echo "Linting Dockerfile ..."
	hadolint Dockerfile
.PHONY: lint

build: lint build-build-image
.PHONY: build

deploy: build publish-build-image
.PHONY: deploy

clean: clean-build-image
.PHONY: clean
