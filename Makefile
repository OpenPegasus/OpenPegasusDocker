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

DOCKER_REGISTRY=kschopmeyer
BUILD_IMAGE=openpegasus-build
RUN_IMAGE=openpegasus-server
SHELL := /bin/bash
DOCKER_TAG := $(shell cat version.txt)
CONTAINER_NAME := "pegasus"
PEGASUS_ENV_VAR_FILE := "pegasus-build-vars.env"

# Definition of strings for the option to start containers in bash or with app
# NOTE: AUTORUN must be empty and not empty string
BASHRUN := "/bin/bash"
AUTORUN :=

# Default for build is to start build container with bash command line
# Alternative values are true, false, variable not set
ifdef BLDDEVMODE
	ifeq ($(BLDDEVMODE), true)
		AUTORUN-BUILD := ${BASHRUN}
	else
		ifeq ($(BLDDEVMODE), false)
			AUTORUN-BUILD := ${AUTORUN}
		else
			$(error BLDDEVMODE must be true or false)
		endif
	endif
else
	AUTORUN_BUILD := ${BASHRUN}
endif

# Default for openpegasus-server is to start wbem server upon run.
# Alternative values are true, false, variable not set.
ifdef RUNDEVMODE
	ifeq ($(RUNDEVMODE), true)
		AUTORUN-SERVER := ${BASHRUN}
	else
		ifeq ($(RUNDEVMODE), false)
			AUTORUN-SERVER := ${AUTORUN}
		else
			$(error RUNDEVMODE must be true or false)
		endif
	endif
else
	AUTORUN_SERVER := ${AUTORUN}
endif

.PHONY: default-goal
default-goal: make build

.PHONY: help
help:
	@echo "Usage:"
	@echo ""
	@echo "  make lint                  Lint the Dockerfile."
	@echo "  make build                 Build the build image."
	@echo "  make publish               Publish, push the build image to a docker image registry."
	@echo "  make clean	                Remove the build image from the local machine."
	@echo "  make run-build-image	    Run the docker build the pegasus server image."
	@echo "  make run-server-image	    Run docker OpenPegasus WBEM server in container"
	@echo "                             with default HTTP and HTTPS ports"
	@echo ""
	@echo "  Docker file for OpenPegasus WBEM Server build.  This file"
	@echo "    builds an OpenPegasus WBEM server in the build container,"
	@echo "    provides tools for testing and provisioning the WBEM server"
	@echo "    Makefile into that container and provides targets for building"
	@echo "    creating and publishing the runtime container."
	@echo ""
	@echo "Build variables"
	@echo "  Docker registry (DOCKER_REGISTRY) = ${DOCKER_REGISTRY}"
	@echo "  Docker image name (BUILD_IMAGE) = ${BUILD_IMAGE}"
	@echo "  Docker image version tag (DOCKER_TAG) = ${DOCKER_TAG}"
	@echo "  Pegasus build environment variables file () = ${PEGASUS_ENV_VAR_FILE}."
	@echo "  This file is required as it defines the pegasus build configuration."
	@echo "  Start run image choice (RUNDEVMODE) = ${RUNDEVMODE}, default start server"
	@echo "  Start run image choice (BLDDEVMODE) = ${BLDDEVMODE}, default start bash"
	@echo "  Values are true/false or not set. May be set on make command line"
	@echo ""
	@echo "NOTE: DOCKER_USER and DOCKER_PASSWORD are requested on deploy"
	@echo ""

.PHONY: create-build-image
create-build-image:
	@echo "Building the docker build image..."
	docker build --rm -t ${DOCKER_REGISTRY}/${BUILD_IMAGE}:$(DOCKER_TAG) .

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
		--env-file=${PEGASUS_ENV_VAR_FILE} \
		-v /var/run/docker.sock:/var/run/docker.sock ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${DOCKER_TAG} ${AUTORUN-BUILD}

.PHONY: run-server-image
run-server-image:
	@echo run the local server container image ${RUN_IMAGE}:${DOCKER_TAG}
	@echo http port = 15988, https port = 15989
	sudo docker run -it --rm  -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 \
		--init --ulimit core=-1 --mount type=bind,source=/tmp/,target=/tmp/ \
		--log-driver=syslog --name ${CONTAINER_NAME} ${RUN_IMAGE}:${DOCKER_TAG} ${AUTORUN-SERVER}

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
