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
RUN_IMAGE=openpegasus-server
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
	@echo "  make run-build-image	    Run the build the pegasus server image."
	@echo "  make run-server-image	    Run OpenPegasus WBEM server in container"
	@echo "                             with default HTTP and HTTPS ports"
	@echo ""
	@echo "  Docker file for OpenPegasus WBEM Server build.  This file"
	@echo "    builds an OpenPegasus WBEM server in the build container,"
	@echo "    provides tools for testing and provisioning the WBEM server"
	@echo "    Makefile into that container and provides targets for building"
	@echo "    creating and publishing the runtime container."
	@echo ""
	@echo "Build variables"
	@echo "  Docker registry = ${DOCKER_REGISTRY}"
	@echo "  Docker image name = ${BUILD_IMAGE}"
	@echo "  Docker image version tag = ${DOCKER_TAG}"
	@echo ""
	@echo "NOTE: DOCKER_USER and DOCKER_PASSWORD are requested on deploy"
	@echo ""

.PHONY: create-build-image
create-build-image:
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

.PHONY: run-build-image
run-build-image:
	@echo Run the build image ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG}
	sudo docker run -it --rm \
		-v /home/${USER}/.ssh:/root/.ssh \
		--env-file=pegasus-build-vars.env \
		-v /var/run/docker.sock:/var/run/docker.sock ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG} /bin/bash

.PHONY: run-server-image
run-server-image:
	@echo run the local server container image ${RUN_IMAGE}:${DOCKER_TAG}
	echo http port = 15988, https port = 15989
	sudo docker run -it --rm  -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 \
		--init --ulimit core=-1 \
		--mount type=bind,source=/tmp/,target=/tmp/ \
		--log-driver=syslog --name pegasus  ${RUN_IMAGE}:${DOCKER_TAG}

# NOTE: Set the last item in the above command to /bin/bash to start the runtime environment
# in bash. The current setting starts cimserver upon container startup and shuts it down when
# the container is stopped.

# TODO: This target specifies the image name including the DOCKER_REGISTRY so only
#       really works when image has been published.
.PHONY: run-openpegasus-image
run-openpegasus-image:
	@echo Example: run the OpenPegasus build image to build the OpenPegasus server image..."
	echo http port = 15988, https port = 15989
	sudo docker run -it --rm  -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 \
	    --log-driver=syslog --name pegasus  ${DOCKER_REGISTRY}/${RUN_IMAGE}:${DOCKER_TAG} /bin/bash

.PHONY: lint
lint:
	@echo "Linting Dockerfile if hadolint exists..."
	# Allow hadolint to fail or not be found
	-hadolint Dockerfile

.PHONY: build
build: lint create-build-image
	@echo "You can start build container with \"make run-build-image\"."

.PHONY: deploy
deploy: build publish-build-image

.PHONY: clean
clean: clean-build-image
