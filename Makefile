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

SHELL := /bin/bash

# Docker Account containing OpenPegasus build and run images
DOCKER_REGISTRY=kschopmeyer
# TODO: Do not want user name in this file.  Having problems with
# getting it from environment so this is temp for 0.13.0 version
DOCKER_USER=kschopmeyer
# Name for the Docker build image
BUILD_IMAGE_NAME=openpegasus-build
# Name for the Docker WBEM server run image
SERVER_IMAGE_NAME=openpegasus-server
# Tag part of the server image naming contained in a file. Typically this
# TODO: Should this be somewhere else than a file since it is just one variable
# identifies the version of OpenPegasus. TODO what about the build image, etc.
DOCKER_SERVER_IMAGE_VERSION="server-image_version.env"
# Tag for the build  and run images.  This is the current version of this repo.
# TODO: The naming is not clean here.  DOCKER_IMAGE_TAG
DOCKER_IMAGE_TAG := $(shell cat version.txt)
# Docker name of the OpenPegasus WBEM server run container
# TODO: Not required in this makefile
RUN_CONTAINER_NAME := "openpegasus"
# Name of file defining the OpenPegasus build environment variables.
# This file defines the compile and test parameters as environment variable,
# consistent with the definitions defined for OpenPegasus build.  See
# the OpenPegasus build and release documentation for more details.
# This file MUST exist. It is included in the build image by the Docker run command
PEGASUS_BUILD_ENV_VAR_FILE := "pegasus-build-vars.env"

REGISTRY_HOSTNAME="kschopmeyer"

# Local and Global versioned Docker name:version of local build image
LOCAL_BUILD_IMAGE_NAME=$(BUILD_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
# Full versioned Docker name of build image including registry hostname prefix
GLOBAL_BUILD_IMAGE_NAME="$(REGISTRY_HOSTNAME)/$(LOCAL_BUILD_IMAGE_NAME)"

# LOCAL and GLOBAL Docker name:version for WBEM server image
LOCAL_SERVER_IMAGE_NAME=$(SERVER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
GLOBAL_SERVER_IMAGE_NAME=$(REGISTRY_HOSTNAME)/$(LOCAL_SERVER_IMAGE_NAME)

# Definition of start mode for each of the containers:
# These variables  can be applied on the command line to control whether the
# containers go directly to their default Entry Points or start with a terminal.

# Thus, the run container can be started with a terminal rather than starting the
# the WBEM server using:
#    make run-server-image RUN=auto

MANUAL_STR := /bin/bash
# AUTO_STR must be empty and not empty string. This is string set into
# the docker run command.
AUTO_STR :=

# Default for build is to start build container with bash command line
# Alternative values are auto (executes docke defined command), manual(starts
# in the console. Make help can be used to see build alternatives),
# or variable not set in which case the creation of the build image defaults to
# auto and the wbem server build image defaults to manual
ifdef BUILD-START
  ifeq ($(BUILD-START),auto)
    BUILD-START-STR = $(AUTO_STR)
  else ifeq ($(BUILD-START),manual)
      BUILD-START-STR = $(MANUAL_STR)
  else
    $(error BUILD-START=$(BUILD-START) invalid, must be auto or manual. Default: manual)
  endif
else
    BUILD-START-STR = $(MANUAL_STR)
endif

# Default for openpegasus-server - automatically start the wbem server.
# Alternative values are manual, auto, variable not set.
ifdef SERVER-START
  $(info SVR_ST $(SERVER-START) found)
  ifeq ($(SERVER-START),auto)
    $(info SVR_ST1 $(SERVER-START) )
    SERVER-START-STR = $(AUTO_STR)
    $(info SERVER-START-STR = $(SERVER-START-STR); mod auto = $(SERVER-START))
  else ifeq ($(SERVER-START),manual)
    $(info SVR_ST2 $(SERVER-START) )

    SERVER-START-STR = $(MANUAL_STR)
    $(info SERVER-START-STR = $(SERVER-START-STR); mod manual = $(SERVER-START))
  else
    $(error SERVER-START=$(SERVER-START) invalid. Must be auto or manual. Default: auto)
  endif
else
  $(info SVR_START= $(AUTO_STR) )
  SERVER-START-STR = $(AUTO_STR)
endif

# Create SET-PEGASUS_GIT_BRANCH_OPTION based on existence of PEGASUS_GIT_BRANCH env var
# TODO: THis is redundant
ifdef PEGASUS_GIT_BRANCH
    # SET_PEGASUS_GIT_BRANCH_OPTION := --env PEGASUS_GIT_BRANCH=$(PEGASUS_GIT_BRANCH)
    $(info Clone git branch: $(PEGASUS_GIT_BRANCH))
endif

# Default target if no target is defined when this file is executed. The default
# is to execute the build target
.PHONY: default-goal
default-goal: make build

.PHONY: help
help:
	@echo "Usage:"
	@echo ""
	@echo "  Makefile for OpenPegasus WBEM Server build.  This file builds OpenPegasus"
	@echo "  WBEM server in the build container, provides tools for testing and"
	@echo "  provisioning the WBEM server Makefile into that container and provides"
	@echo "  targets for building creating and publishing the runtime container."
	@echo "  Targets:"
	@echo "  make lint                Lint the Dockerfile."
	@echo "  make build               Build the build Docker image."
	@echo "  make publish             Push the build image to Docker image registry."
	@echo "  make publish-run-image   Push the server image to Docker image registry."
	@echo "                             Allows publishing server image from this Makefile"
	@echo "  make clean	              Remove the build image from the local machine."
	@echo "  make run-build-image     Run the docker build image. Env var PEGASUS_GIT_BRANCH"
	@echo "                             accepted on cmd and determines if git clones branch or tag. If env var PEG_HOST_DIR set"
	@echo "                             the host will be used as the Pegasus work dir."
	@echo "                             so the pegasus source will be in this host dir."
	@echo "                             PEGASUS_GIT_BRANCH accepted on cmd line."
	@echo "                             If PEG_HOST_DIR exists and OpenPegasus exists, git is not cloned."
	@echo "  make run-server-image    Run docker OpenPegasus WBEM server in container"
	@echo "                             with default HTTP and HTTPS ports"
	@echo ""
	@echo "OpenPegaus Build variables and image variables"
	@echo "  DOCKER_REGISTRY=$(DOCKER_REGISTRY). Docker registry"
	@echo "  BUILD_IMAGE_NAME=${BUILD_IMAGE_NAME}. Docker build image name."
	@echo "  DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG}. Docker image version tag."
	@echo "  RUN_IMAGE_NAME=${RUN_IMAGE_NAME}. Docker run image name."
	@echo "  PEGASUS_BUILD_ENV_VAR_FILE=${PEGASUS_BUILD_ENV_VAR_FILE}"
	@echo "    File containing Pegasus build environment variables used in compile"
	@echo "    of OpenPegasus. Defined in Dockerfile."
	@echo "    Defines the pegasus compile configuration env variables."
	@echo "  BUILD-START=$(BUILD-START);  default manual. Start build image choice."
	@echo "  SERVER-START=$(SERVER-START);  (manual/auto) default auto. Start run image choice"
	@echo "    Values are 'auto'/'manual' or not set. May be set on make command"
	@echo "    line or env var."  make run-server-image SERVER-START=manual"
	@echo "  PEGASUS_GIT_TAG=$(PEGASUS_GIT_TAG)"
	@echo "  PEGASUS_GIT_BRANCH=$(PEGASUS_GIT_BRANCH) - Optional. If defined,"
	@echo "    names a directory in the host system where the cloned OpenPegasus will"
	@echo "    be available after make repository-checkout rather than in the container."
	@echo "    Can be used during developmentto allow access to editors"
	@echo "    and other tools rather than installing them in the container."
	@echo "  DOCKER_PASSWORD is requested for publish if not supplied"
	@echo ""

.PHONY: create-build-image
create-build-image:
	@echo "Building the docker build image..."
	docker build --rm -t $(DOCKER_REGISTRY)/$(BUILD_IMAGE_NAME):$(DOCKER_IMAGE_TAG) .

.PHONY: publish-build-image
publish-build-image:
	@echo "Publishing the wbem server build image $(DOCKER_REGISTRY)/$(BUILD_IMAGE_NAME)"
	docker logout
	docker image tag $(LOCAL_BUILD_IMAGE_NAME) $(GLOBAL_BUILD_IMAGE_NAME)
	# User must supply password at terminal
	docker login -u $$(DOCKER_USER)
	docker push $(GLOBAL_BUILD_IMAGE_NAME)
	docker logout

.PHONY: clean-build-image
clean-build-image:
	@echo "Removing the build image $(DOCKER_USER)/$(BUILD_IMAGE_NAME):$(DOCKER_IMAGE_TAG) ..."
	-docker rmi $(DOCKER_REGISTRY)/$(BUILD_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
	@echo "Removing the build image $(BUILD_IMAGE_NAME):$(DOCKER_IMAGE_TAG) ..."
	-docker rmi $(BUILD_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

.PHONY: run-build-image
run-build-image:
	@echo "BUILD-START=(BUILD-START); SERVER-START=$(SERVER-START)"
	@echo "Run the build image $(GLOBAL_BUILD_IMAGE_NAME)"
    ifdef PEGASUS_GIT_BRANCH
        $(info Using OpenPegasus git branch: $(PEGASUS_GIT_BRANCH))
        DOCKER_RUN_ENV_OPTION = "-env $(PEGASUS_GIT_BRANCH)"
    else
        DOCKER_RUN_ENV_OPTION = ""
    endif
    $(info DOCKER_RUN_ENV_OPTION = $(DOCKER_RUN_ENV_OPTION))
	sudo docker run -it --rm \
		-v /home/$(USER)/.ssh:/root/.ssh \
		$(DOCKER_RUN_ENV_OPTION) \
		--env-file=$(PEGASUS_BUILD_ENV_VAR_FILE) \
		--env-file=$(DOCKER_SERVER_IMAGE_VERSION) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(GLOBAL_BUILD_IMAGE_NAME) \
		$(BUILD-START-STR)

.PHONY: run-server-image
run-server-image:
	@echo "SERVER-START = $(SERVER-START); str = $(SERVER-START-STR)"
	@echo run the local server container image $(LOCAL_SERVER_IMAGE_NAME)
	@echo http port = 15988, https port = 15989
	sudo docker run -it --rm \
		-p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 \
		--init --ulimit core=-1 \
		--mount type=bind,source=/tmp/,target=/tmp/ \
		--log-driver=syslog \
		--net=bridge \
		--name pegasus  \
		$(LOCAL_SERVER_IMAGE_NAME) \
		$(SERVER-START-STR)
# TODO: Extend with option to execute a command
# cimserver cimserver traceLevel=4 traceComponent=ALL

.PHONY: publish-server-image
publish-server-image:
	@echo "Publish image WBEM Server image to private image registry..."
    # Docker password must be supplied at terminal
	docker login -u $$(DOCKER_USER)
	docker tag $(LOCAL_SERVER_IMAGE_NAME) $(GLOBAL_SERVER_IMAGE_NAME)
	docker push $(GLOBAL_SERVER_IMAGE_NAME)
	docker logout
	@echo "Makefile: Target $@ complete"

.PHONY: lint
lint:
	@echo "Linting Dockerfile if hadolint exists..."
	# Allow hadolint to fail or not be found
	-hadolint Dockerfile

.PHONY: build
build: lint create-build-image
	@echo "Start build container with \"make run-build-image\"."

.PHONY: publish
publish: publish-build-image

.PHONY: clean
clean: clean-build-image
