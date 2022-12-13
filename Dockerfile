######## Start builder #######
FROM ubuntu:20.04

# Ignore DL3002: Last user should not be root.
# hadolint ignore=DL3002
USER root

# Required so that pipes work properly in the Dockerfile
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

# Package installations
# Includes packages for docker, OpenPegasus support packages, and
# packages to support the development environment

# Ignore DL3005 that disallows apt-get upgrade
# hadolint ignore=DL3005
# Ignore DL3008: Pin versions in apt-get install.
# hadolint ignore=DL3008
# NOTE: The upgrade is absolutely required for ubuntu 20.04 becase the
# pam dev lib was left out of the original release.
# The libpam0g-dev may have different names under other linux distributions.
# the --no-install-recommends significantly reduces docker image size

# Ignore DL3005 that disallows apt-get upgrade
# Ignore DL3008: Pin versions in apt-get install.
# hadolint ignore=DL3005,DL3008
# This installs ubuntu updates and build support tools into the build container
# Since the build container is used only in the process of building and testing
# OpenPegasus, size is not important
# This includes a number of development support tools that might prove useful
# if the OpenPegasus code is to be inspected or modified
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    openssl \
    docker.io \
    # Build tools and the gcc compiler
    build-essential \
    # Some development support tools that might be useful
    ack-grep \
    git \
    tmux \
    curl \
    vim \
    # The following libraries are required to compile OpenPegasus
    libssl-dev \
    libpam0g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Build Docker and git repository
# These environment variables may be overridden by the pegaus-build-var.env
# file but are probably

# Docker repository name and user name
ENV DOCKER_REGISTRY=kschopmeyer
ENV DOCKER_USER

# OpenPegasus Server name and version
ENV SERVER_IMAGE="openpegasus-server"
# TODO: Get version from version.txt might be better
ENV SERVER_IMAGE_VERSION="0.1.2"

# Git Repository name
ENV PEGASUS_GIT_REPOSITORY=http://github.com/OpenPegasus/OpenPegasus.git

# OpenPegasus git repository branch name and tag to checkout for the OpenPegasus build
# Use http to clone repository because no authentication required. Either the
# tag or branch define what to clone. The  if neither is set default is to clone main
# If PEGASUS_GIT_TAG set, only that tagged branch is cloned.  This can be used
# to build with tagged OpenPegasus releases. This must be used to build a
# container with a released pegasus version.
#
# If PEGASUS_GIT_BRANCH is set, the complete git repository is cloned and
# the git checkout command used to activate the branch defined by
# PEGASUS_GIT_BRANCH. This can be useful for testing OpenPegasus in a container

# PEGASUS_GIT_TAG and PEGASUS_GIT_BRANCH are mutually exclusive
ENV PEGASUS_GIT_TAG="v2.14.3"
ENV PEGASUS_GIT_BRANCH=""

#
# Define environment variables for the Pegasus file paths
# Normally these environment variables should not be changed
#

# Root directory for OpenPegasus git clone, source code, and the build results.
ENV PEGASUS_BUILD_ROOT=/root/build_dir

# PEGASUS_HOME defines the target location for pegasus build output including
# object files, executables, the repository, and security files
ENV PEGASUS_HOME=${PEGASUS_BUILD_ROOT}/openpegasus_home

# PEGASUS_GIT_HOME defines where git clones the OpenPegasus repository
ENV PEGASUS_GIT_HOME=${PEGASUS_BUILD_ROOT}/OpenPegasus

# PEGASUS_ROOT defines the top level of the pegasus source files (pegasus)
ENV PEGASUS_ROOT=${PEGASUS_BUILD_ROOT}/OpenPegasus/pegasus

# Create directory structure for OpenPegasus built libraries, executables,
# etc.
RUN mkdir -p ${PEGASUS_HOME} && \
    mkdir -p /root/.ssh

# Add path for created executables to PATH for server start, OpenPegasus
# command line utilities and tests.
ENV PATH=${PEGASUS_HOME}/bin:$PATH

# NOTE: Running the build container requires that the option --env-file be
# defined.
#
# OpenPegasus compile variables. See OpenPegasus documentation for more
# detailed information on particular variables.
# These environment variables are used during the
# build of OpenPegasus (They define the compile characteristics of
# OpenPegasus) and the functions enabled.

# Settings that are flags, with values set to true, enable the action
# simply through the existence of the variable.  The variables value has no
# effect.
# See OpenPegasus/pegasus/doc/BuildAndReleaseOptiions.html for more detailed information
# on the options

# Platform defined for the docker image
# This should not change since we will always build the run container with
# 64 bit linux and expect an x86_64 platform
ENV PEGASUS_PLATFORM=LINUX_X86_64_GNU

# Add the Makefile and Dockerfile for building the server image based on
# the build image
COPY ./Makefile_wbemserver-build ${PEGASUS_BUILD_ROOT}/Makefile
COPY ./Dockerfile_wbemserver-build ${PEGASUS_BUILD_ROOT}/Dockerfile

# OpenPegasus Build folder
WORKDIR ${PEGASUS_BUILD_ROOT}

# Call the make default target which builds OpenPegasus and deploys the
# OpenPegasus image to the local Docker repository
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["make"]
