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

# This make file is copied into the container as Makefile and provides the
# targets to build and test OpenPegasus and to create the resulting
# server image which will contain an executable OpenPegasus image.
#

# Usage:
#
# make          Same as "make all".
# make all      Build and publish a server image.
# make build    Build the server image.
# make test     Run tests against the built server.
# make deploy   Build the local OpenPegasus server image.
# make publish  Push the server image to a predefined docker repository
# make clean    Remove build output, build image and server images.
#
# Notes:
#
# 1. Build only runs the build and tests the server.  The $(PEGASUS_HOME) contains
#    the WBEM server run components, and repository.
# 2. Deploy will build, test, and create the server image and push it to the

# 2. Publish will push a copy of the pegasus wbem server run image to a named
#    remote registry.
# 3. The ~/.ssh folder and the Docker-in-Docker folder need to be mapped
#    volumes when running a make command.
#
# 4. See the targets in the Makefile that builds the build image for detailed
#    examples of the docker commands to start the build image and the
#    run image.
#
# 5. The full test suite can only be run with PEGASUS_INTEROP_NAMESPACE = root/PG_InterOp.
#    Some of the client and support files have the namespace hard coded into
#    the files.  See the Makefile pegasus/Makefile.interop which is a tool
#    to modify the hardcoded namespace info and also documents the required with
#    using interop or root/interop as interop namespace

# No built-in rules needed:
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

SHELL=/bin/bash

# Top-level build target. This is used as target if cmd line is "make"
.PHONY: default-target
default-target: build deploy

.PHONY: help
help:
	@echo "Usage:"
	@echo "Targets:"
	@echo "  make               make build, deploy. Downloads, builds, tests"
	@echo "                     OpenPegasus and builds wbem server run image."
	@echo "  make config-info   OpenPegasus build and run configuration information."
	@echo "  make build         Clone OpenPegasus compile it and execute tests."
	@echo "      build subtargets:"
	@echo "        make checkout-repository"
	@echo "        build-server"
	@echo "        test-server"
	@echo "  make deploy        Build run image into local docker repository."
	@echo "                     with <Name>:<version> but no <repository name>."
	@echo "       deploy subtargets:"
	@echo "         make build-image - Create the local server run image."
	@echo "         make provision-server - Install repository, certs, etc."
	@echo "         make build-server-image - clean cruft and build the local image"
	@echo "         make remove-components & clean cruft from build components."
	@echo "  make publish       Push the server image to an image registry."
	@echo "  make clean         Remove the build image from the local machine."
	@echo "  make clobber       Remove everything created to ensure clean start."
	@echo ""
	@echo "Build and run configuration variables. See: Dockerfile and pegaus-build-vars.env"
	@echo "Git and Docker variables for image build "
	@echo "  SERVER_IMAGE_NAME = The name of the server docker image"
	@echo "  SERVER_VERSION = The name of the server docker image version"
	@echo "  PEGASUS_GIT_REPOSITORY = The uri of the OpenPegasus github repo"
	@echo "  PEGASUS_GIT_BRANCH = OpenPegasus git branch. Overrides PEGASUS_GIT_TAG"
	@echo "    Checkout current main and switch to defined branch."
	@echo "  PEGASUS_GIT_TAG = OpenPegasus git tag. Ignore when PEGASUS_GIT_BRANCH set"
	@echo "     Change this to select particular version of pegasus used"
	@echo "  DOCKER_REGISTRY = Public registry where run image published"
	@echo ""
	@echo "Build and test control variables."
	@echo "  PEGASUS_TEST_TARGET Defines tests suite to run"
	@echo ""
	@echo "  OpenPegasus build variables are defined in a separate file"
	@echo "  (ex. pegasus-build-vars.env) which must be part of the"
	@echo "  Docker run statement that starts the build image."
	@echo "  Docker run attaches this file to the build image with the"
	@echo "  run option --env-file.  OpenPegasus will not build without this file."
	@echo ""
	@echo "NOTE: DOCKER_USER and DOCKER_PASSWORD are requested on publish"
	@echo ""

build.done: checkout-repository build-server test-server
	@echo "done" >$@
	@echo "Makefile: Done checkout, build, test OpenPegasus"
	@echo "Makefile: Target $@ complete"

.PHONY: build
build: build.done
	@echo "OpenPegasus cloned, compiled, and tested."
	@echo "done" >$@
	@echo "Makefile: Target $@ done."

deploy.done: build.done provision-server remove-components docker-image-build
	@echo "OpenPegasus run image provisioned and image created."
	@echo "Makefile: Target $@ done."

.PHONY: deploy
deploy: deploy.done
	@echo "done" >$@
	@echo "Makefile: Target $@ done."

.PHONY: test
test: test-server

.PHONY: clean
clean: clean-build docker-remove-server-images

.PHONY: clobber
clobber:
	@echo "Remove build results and git checkout"
	@echo "Remove *.done files"
	rm -f *.done
	@echo "Remove of PEGASUS_HOME data in ${PEGASUS_HOME}"
	rm -rf ${PEGASUS_HOME}/*
	@echo "Remove pegasus clone directories ${PEGASUS_HOME}"
	rm -rf OpenPegasus

# Subtargets for build target

checkout-repository.done:
	@echo "Cloning OpenPegasus GitHub repository..."

	@echo "Set global git config to ignore certificate..."
	@git config --global http.sslverify false

    # PEGASUS_GIT_BRANCH, overrides PEGASUS_GIT_TAG, Clones main and checkout branch
    # If PEGASUS_GIT_BRNCH exists it must be main or a valid git branch name.
    # NOTE: .ONESHELL  not defined in this script the following defined as single statement

	@if [ ! -z ${PEGASUS_GIT_BRANCH} ]; then \
        echo "Cloning OpenPegasus github repo main branch to WBEM root directory"; \
        if [ ! -d ${PEGASUS_ROOT} ]; then \
            git clone ${PEGASUS_GIT_REPOSITORY}; \
            echo "OpenPegasus ${PEGASUS_GIT_REPOSITORY} main cloned."; \
            if [  ${PEGASUS_GIT_BRANCH} != "main" ]; then \
                echo "git checkout  branch ${PEGASUS_GIT_BRANCH}."; \
                git -C ${PEGASUS_GIT_HOME} checkout ${PEGASUS_GIT_BRANCH}; \
            fi; \
        fi; \
    else \
        echo "Cloning OpenPegasus github repo tag ${PEGASUS_GIT_TAG} to WBEM root directory"; \
        if [ ! -d ${PEGASUS_ROOT} ]; then \
            git clone ${PEGASUS_GIT_REPOSITORY} --branch ${PEGASUS_GIT_TAG}; \
            echo "OpenPegasus ${PEGASUS_GIT_REPOSITORY} tag ${PEGASUS_GIT_TAG} cloned."; \
        fi; \
    fi;

	@git -C ${PEGASUS_GIT_HOME} status

	@echo "done" >$@
	@echo "Makefile: Target $@ complete"


.PHONY: checkout-repository
checkout-repository: checkout-repository.done
	@echo "done" >$@
	@echo "Target $@ complete"

build-server.done: checkout-repository.done
	@echo "Building the server using pegasus source..."
	$(MAKE) -C ${PEGASUS_ROOT} clean
	$(MAKE) -C ${PEGASUS_ROOT} build
	@echo "List the current build variables in pegasus-build-variables.env..."
	@export | grep PEGASUS > pegasus-build-variables.env
	@echo "done" >$@
	@echo "Makefile: Target $@ complete"

.PHONY: build-server
build-server: build-server.done

# test-server target.  Test server only if PEGASUS_TEST_TARGET has value and
# build-server.done. Note that in any case the OpenPegasus test repository and
# providers are installed which tests much of OpenPegasus.
# tests could be executed manually by running make <test target> in the
# pegasus directory.

.PHONY: test-server
test-server.done: build-server.done
	@echo "Testing the WBEM server in the build container..."

	@echo "Create the server build test repository..."
	@$(MAKE) create_test_repository

	@if [[ -z ${PEGASUS_TEST_TARGET} ]]; then \
        echo "Run all tests: PEGASUS_TEST_TARGET=alltests"; \
        export PEGASUS_TEST_TARGET=alltests; \
    fi; \
    echo "Testing the server build with ${PEGASUS_TEST_TARGET}."; \
    $(MAKE) -C ${PEGASUS_ROOT} ${PEGASUS_TEST_TARGET}; \
    echo "NOTE: Docker repository not clean. Contains data from test."; \

	@echo "done" >$@
	@echo "Makefile: Target $@ complete"

.PHONY: test-server
test-server: test-server.done
	@echo "Makefile: Target $@ complete"

# Build the CIM repository defined for the OpenPegasus testsuite.  This is
# based on the the targets defined in pegasus/TestMakefile. This defines the
# interop namespace and adds a number of other test namespaces

# Build the CIM repository defined for the OpenPegasus testsuite.  This is
# based on the the targets defined in pegasus/TestMakefile. This defines the
# interop namespace as PG_InterOp and adds a number of other test namespaces
# to support the OpenPegasus test suite.
.PHONY: create_test_repository
create_test_repository:
	@echo "Create the repository and install providers..."
	$(MAKE) -C ${PEGASUS_ROOT} repository
    # specific repository  Schema extensions extensions.
	$(MAKE) -C ${PEGASUS_ROOT} testrepository
	@echo "Test repository created"
	@echo "Makefile: Target $@ complete"

# Default provision-server.  This creates the repository and test repository
# that are the same as the test repository except that the namespace is the
# namespace defined in the PEGASUS_INTEROP_NAMESPACE variable.
# TODO: Need way to override this with user defined provision-server

.PHONY: provision-server
provision-server:
	@echo "Provision the server in build container based on Pegasus tests..."
	$(MAKE) -C ${PEGASUS_ROOT} repository
	$(MAKE) -C ${PEGASUS_ROOT} testrepository

	@echo "Makefile: Target $@ complete"

.PHONY: remove-components
remove-components:
	@echo "Remove the server unwanted files in the build container..."

	@echo "Remove all test executables"
    # TODO: Should we leave some sort of validity test. See OpenPegasus 2.14.4 sanity test
	rm -f ${PEGASUS_HOME}/bin/Test* ${PEGASUS_HOME}/bin/mu
	rm -f ${PEGASUS_HOME}/stripline ${PEGASUS_HOME}/stripcrs ${PEGASUS_HOME}/chksrc

	@echo "Remove object files"
	rm -rf ${PEGASUS_HOME}/obj

	@echo "Remove trace files"
	rm -f ${PEGASUS_HOME}/trace/*

	@echo "Remove unused Test files"
	rm -f ${PEGASUS_HOME}/test/StressTestClients -rf
	rm -f ${PEGASUS_HOME}/test/StressTestController -rf

	@echo "Remove unwanted certs"
	rm -f ${PEGASUS_HOME}/test/testmonth*.* -rf

	@echo "Makefile: Target $@ complete"

# Subtargets for publish target

.PHONY: docker-image-build
docker-image-build: remove-components

	@echo "Building the OpenPegasus WBEM Server image..."

	@echo "Build docker local image (no docker repository component) image..."
	docker build --tag ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION} .
	@echo "Build docker local image ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION} built"
	@echo "This image can be run with make run-server-image using Makefile from repo."
	@echo "Makefile: Target $@ complete"

.PHONY: publish
publish:
	@echo "Pushing the built WBEM Server image to private image registry..."

	docker logout
    # Docker password must be supplied at terminal
	docker login -u $${DOCKER_USER}
	docker tag ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION} ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}
	docker push ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}
	docker logout
	@echo "Makefile: Target $@ complete"

# Subtargets for clean target
.PHONY: clean-build
clean-build:
	@echo "Cleaning the pegasus build directories..."

	@echo "Clean and clobber the pegasus build components"
	$(MAKE) -C ${PEGASUS_ROOT} clobber
	$(MAKE) -C ${PEGASUS_ROOT} clean
	@echo "Makefile: Target $@ complete"

.PHONY: docker-remove-server-images
docker-remove-server-images:
	@echo "Removing server images..."

	@echo "Removing the repository tagged server image..."

	docker rmi ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}

	@echo "Removing the server image..."
	docker rmi ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}
	@echo "Makefile: Target $@ complete"

.PHONY: config-info
config-info:
	@echo "Build Environment variables"
	@export | grep PEGASUS
