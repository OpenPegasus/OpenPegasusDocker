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
# Tag for the build  and run images.  This is the current version of this repo.
DOCKER_IMAGE_TAG := $(shell cat version.txt)
# Docker name of the OpenPegasus WBEM server run container
# TODO: Not required in this makefile
CONTAINER_NAME := "openpegasus"
# Name of file defining OpenPegasus build environment variables.
# This file MUST exist and it attached to the build image by the Docker run command
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
  $(info SVR_ST3 $(SERVER-START) )
  SERVER-START-STR = $(AUTO_STR)
endif

# Create SET-PEGASUS_GIT_BRANCH option base on existence of PEGASUS_GIT_BRANCH env var
ifdef PEGASUS_GIT_BRANCH
    SET_PEGASUS_GIT_BRANCH_OPTION := --env PEGASUS_GIT_BRANCH=$(PEGASUS_GIT_BRANCH)
else
   SET_PEGASUS_GIT_BRANCH_OPTION :=
endif

$(info "branch" $(PEGASUS_GIT_BRANCH) flag = SET_PEGASUS_GIT_BRANCH_OPTION)


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
	@echo "  make run-build-image     Run the docker build the pegasus server image."
	@echo "                             PEGASUS_GIT_BRANCH accepted on cmd line."
	@echo "  make run-server-image    Run docker OpenPegasus WBEM server in container"
	@echo "                             with default HTTP and HTTPS ports"
	@echo ""
	@echo "Build variables"
	@echo "  Docker registry (DOCKER_REGISTRY) = $(DOCKER_REGISTRY)"
	@echo "  Docker image name (BUILD_IMAGE_NAME) = ${BUILD_IMAGE_NAME}"
	@echo "  Docker image version tag (DOCKER_IMAGE_TAG) = ${DOCKER_IMAGE_TAG}"
	@echo "  Pegasus build environment variables file = ${PEGASUS_BUILD_ENV_VAR_FILE}."
	@echo "     (${PEGASUS_BUILD_ENV_VAR_FILE}) is required;"
	@echo "     it defines the pegasus build configuration."
	@echo "  Start build image choice BUILD-START;  default manual"
	@echo "  Start run image choice SERVER-START;  default auto"
	@echo "     Values are 'auto'/'manual' or not set. May be set on make command"
	@echo "     line or env var."  make run-server-image SERVER-START=manual
	@echo ""
	@echo "NOTE: DOCKER_PASSWORD is requested for publish"
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
	@echo "Use git branch $(SET-PEGASUS-GIT-BRANCH)"
	sudo docker run -it --rm \
		-v /home/$(USER)/.ssh:/root/.ssh $(SET_PEGASUS_GIT_BRANCH_OPTION)\
		--env-file=$(PEGASUS_BUILD_ENV_VAR_FILE) \
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
