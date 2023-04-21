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
DOCKER_USER=kschopmeyer
DOCKER_REGISTRY=$(DOCKER_USER)
BUILD_IMAGE=openpegasus-build
RUN_IMAGE=openpegasus-server

SHELL := /bin/bash

# Major OpenPegasus variables used.
# Docker Account containing OpenPegasus build and run images
DOCKER_REGISTRY=kschopmeyer
# Name for the Docker build image
BUILD_IMAGE=openpegasus-build
# Name for the Docker WBEM server run image
RUN_IMAGE=openpegasus-server
# Tag for the build  and run images.  This is the current version of this repo.
DOCKER_TAG := $(shell cat version.txt)
# Name of the OpenPegasus WBEM server run container
CONTAINER_NAME := "pegasus"
# Name of file defining most Git and OpenPegasus build environment variables.
# This file MUST exist and it attached to the build image by the Docker run command
PEGASUS_ENV_VAR_FILE := "pegasus-build-vars.env"

# Definition of startup mode for each of the containers:
# These variables  can be applied on the command line to control whether the
# containers go directly to their default Entry Points or start with a terminal.

# Thus, the run container can be started with a terminal rather than starting the
# the WBEM server using:
#    make run-server-image RUN=auto

MANUAL := "/bin/bash"
# NOTE: AUTO must be empty and not empty string. This is string set into
# the docker run command.
AUTO :=

# Default for build is to start build container with bash command line
# Alternative values are auto (executes docke defined command), manual(starts
# in the console. Make help can be used to see build alternatives),
# or variable not set in which case the creation of the build image defaults to
# auto and the wbem server build image defaults to manual
ifdef BUILD-START-MODE
  ifeq ($(BUILD-START-MODE),auto)
    BUILD-START-STR = ${AUTO}
  else
    ifeq ($(BUILD-START-MODE),manual)
      BUILD-START-STR = ${MANUAL}
    else
      $(error BUILD-START-MODE=${BUILD-START-MODE} invalid, must be auto or bash. Default: manual)
    endif
  endif
else
    BUILD-START-STR = ${MANUAL}
endif

# Default for openpegasus-server is to start wbem server upon run.
# Alternative values are true, false, variable not set.
ifdef SERVER-START-MODE
  ifeq ($(SERVER-START-MODE),auto)
    SERVER-START_STR = ${MANUAL}
  else
    ifeq ($(SERVER-START-MODE),manual)
      SERVER-START_STR = ${AUTO}
    else
      $(error SERVER_START_MODE=${SERVER_START_MODE} invalid. Must be auto or manual. Default: auto)
    endif
  endif
else
  SERVER-START_STR = ${AUTO}
endif

# Default target if no target is defined when this file is executed. The default
# is to execute the build target
.PHONY: default-goal
default-goal: make build

.PHONY: help
help:
	@echo "Usage:"
	@echo ""
	@echo "  make lint                  Lint the Dockerfile."
	@echo "  make build                 Build the build image."
	@echo "  make publish               Push the build image to Docker image registry."
	@echo "  make publish-run-image     Push the server image to Docker image registry."
	@echo "                               Allows publishing server image from this Makefile"
	@echo "  make clean	                Remove the build image from the local machine."
	@echo "  make run-build-image       Run the docker build the pegasus server image."
	@echo "  make run-server-image      Run docker OpenPegasus WBEM server in container"
	@echo "                             with default HTTP and HTTPS ports"
	@echo ""
	@echo "  Docker file for OpenPegasus WBEM Server build.  This file"
	@echo "    builds an OpenPegasus WBEM server in the build container,"
	@echo "    provides tools for testing and provisioning the WBEM server"
	@echo "    Makefile into that container and provides targets for building"
	@echo "    creating and publishing the runtime container."
	@echo ""
	@echo "Build variables"
	@echo "  Docker image name = ${BUILD_IMAGE}"
	@echo "  Docker image version tag = ${DOCKER_TAG}"
	@echo "  Docker registry (DOCKER_REGISTRY) = ${DOCKER_REGISTRY}"
	@echo "  Docker image name (BUILD_IMAGE) = ${BUILD_IMAGE}"
	@echo "  Docker image version tag (DOCKER_TAG) = ${DOCKER_TAG}"
	@echo "  Pegasus build environment variables file () = ${PEGASUS_ENV_VAR_FILE}."
	@echo "     This file is required as it defines the pegasus build configuration."
	@echo "  Start build image choice BUILD-START-MODE = ${BUILD-START-MODE}, default manual"
	@echo "  Start run image choice SERVER-START-MODE = ${SERVER-START-MODE}, default auto"
	@echo "     Values are auto/manual or not set. May be set on make command line or env var"
	@echo ""
	@echo ""
	@echo "NOTE: DOCKER_PASSWORD is requested for publish"
	@echo ""

.PHONY: create-build-image
create-build-image:
	@echo "Building the docker build image..."
	docker build --rm -t ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG) .

.PHONY: publish-build-image
publish-build-image:
	@echo "Publishing the wbem server build image..."
	docker logout
	docker image tag ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG) ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG}
	# User must supply password at terminal
	docker login -u $${DOCKER_USER}
	docker push ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG)
	docker logout

.PHONY: publish-server-image
publish-server-image:
	@echo "Pushing the built WBEM Server image to Dockerimage registry..."
	docker logout
	docker tag ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION} ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${DOCKER_TAG}
	docker login -u $${DOCKER_USER}
	docker push ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${DOCKER_TAG}
	docker logout

.PHONY: clean-build-image
clean-build-image:
	@echo "Removing the build image ${DOCKER_USER}/${BUILD_IMAGE}:$(DOCKER_TAG) ..."
	-docker rmi ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG)
	@echo "Removing the build image ${BUILD_IMAGE}:$(DOCKER_TAG) ..."
	-docker rmi ${BUILD_IMAGE}:$(DOCKER_TAG)

.PHONY: run-build-image
run-build-image:
	@echo "BUILD-START-MODE = ${BUILD-START-MODE} SERVER-START-MODE = ${SERVER-START-MODE}"
	@echo Run the build image ${DOCKER_USER}/${BUILD_IMAGE}:${DOCKER_TAG}
	sudo docker run -it --rm \
		-v /home/${USER}/.ssh:/root/.ssh \
		--env-file=${PEGASUS_ENV_VAR_FILE} \
		-v /var/run/docker.sock:/var/run/docker.sock ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG} ${BUILD-START-STR}

.PHONY: run-server-image
run-server-image:
	@echo "SERVER-START-MODE = ${SERVER-START-MODE}"
	@echo run the local server container image ${RUN_IMAGE}:${DOCKER_TAG}
	@echo http port = 15988, https port = 15989
	sudo docker run -it --rm  -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 \
		--init --ulimit core=-1 \
		--mount type=bind,source=/tmp/,target=/tmp/ \
		--log-driver=syslog --name pegasus  ${RUN_IMAGE}:${DOCKER_TAG} ${SERVER_START_STR}

.PHONY: lint
lint:
	@echo "Linting Dockerfile if hadolint exists..."
	# Allow hadolint to fail or not be found
	-hadolint Dockerfile

.PHONY: build
build: lint create-build-image
	@echo "You can start build container with \"make run-build-image\"."

.PHONY: publish
publish: publish-build-image

.PHONY: clean
clean: clean-build-image
