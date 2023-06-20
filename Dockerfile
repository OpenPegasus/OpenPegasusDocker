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
    # Build tools, the gcc compiler, and
    # development support tools that are required
    build-essential \
    git \
    # Network tools useful for development.  I.e. talking to host
    # net-tools installs ifconfig, iproute2 install ip command
    net-tools \
    iproute2 \
    iputils-ping \
    curl \
    # Development tools that are optional but support developing in container
    tmux \
    vim \
    ack-grep \
    # The following libraries are required to compile OpenPegasus
    libssl-dev \
    libpam0g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Build Docker and git repository
# These environment variables may be overridden by the pegaus-build-var.env
# file but are probably

# Docker repository name and user name. Docker image repository name and user
# name to access the repository
ENV DOCKER_REGISTRY=kschopmeyer
ENV DOCKER_USER=kschopmeyer

# OpenPegasus Server image name
ENV SERVER_IMAGE="openpegasus-server"
# TODO: Get version from version.txt might be better
ENV SERVER_IMAGE_VERSION="0.1.3"
# The following fails.
# ENV SERVER_IMAGE_VERSION=$(shell cat version.txt)

# Git OpenPegasus Repository name. Contains OpenPegasus source code
ENV PEGASUS_GIT_REPOSITORY=http://github.com/OpenPegasus/OpenPegasus.git

# OpenPegasus git repository branch name and tag to checkout for the
# OpenPegasus build # Use http to clone repository because no authentication
# required. Either the # tag or branch define what to clone. The  if neither is
# set default is to clone main # If PEGASUS_GIT_TAG set and PEGASUS_GIT_BRANCH is
# not set, only that tagged branch is cloned.  This can be used # to build with
# tagged OpenPegasus releases. PEGASUS_GIT_TAG is normally used to build a #
# container with a released pegasus version.
#
# If PEGASUS_GIT_BRANCH is set, the complete git repository is cloned and
# the git checkout command used to activate the git branch defined by
# PEGASUS_GIT_BRANCH. This can be useful for testing OpenPegasus in a container.
# The default is the main branch

# PEGASUS_GIT_TAG and PEGASUS_GIT_BRANCH define the github source tag/branch
# for cloning OpenPegasus.
# The existence of PEGASUS_GIT_BRANCH env variable overrides PEGASUS_GIT_TAG.
# PEGASUS_GIT_TAG defines a releas tag as the source. It is preset to the
# current latest release of OpenPegasus.

ENV PEGASUS_GIT_TAG="v2.14.4"

# PEGASUS_GIT_BRANCH. This can be useful for testing OpenPegasus  git branches
# in a container. The PEGASUS_GIT_BRANCH must contain a valid git branch
# name (including the main branch).
# Uncomment the following line to clone current git main branch. Change main to
# a valid git branch name to clone that branch. An alternative is to include
# --env PEGASUS_GIT_BRANCH=<branch name on the Docker run command for the build
# image or simple append PEGASUS_GIT_BRANCH=<branch name> to the
# make run-build-server Makefile target.

# ENV PEGASUS_GIT_BRANCH="main"

#
# Environment variables for the Pegasus file paths
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
# OpenPegasus build variables. See OpenPegasus documentation for more
# detailed information on particular variables.
# These environment variables are used during the
# build of OpenPegasus (They define the compile characteristics of
# OpenPegasus) and the functions enabled.

# Settings that are flags, with values set to true, enable the action
# simply through the existence of the variable.  The variables value has no
# effect.
# See OpenPegasus/pegasus/doc/BuildAndReleaseOptiions.html for more detailed
# information on the options

# Platform defined for the docker image
# This should not change since we will always build the run container with
# 64 bit linux and expect an x86_64 platform
ENV PEGASUS_PLATFORM=LINUX_X86_64_GNU

# Add the Makefile and Dockerfile for building the server image based on
# the build image
COPY ./Makefile_wbemserver-build.mak ${PEGASUS_BUILD_ROOT}/Makefile
COPY ./Dockerfile_wbemserver-build ${PEGASUS_BUILD_ROOT}/Dockerfile

# Copy any files in the supplementary_run_files directory to the same named
# directory in the build image.  These files will then be copied to the
# build image in the same directory name.
COPY ./supplementary_run_files ${PEGASUS_BUILD_ROOT}/supplementary_run_files/

# OpenPegasus Build folder
WORKDIR ${PEGASUS_BUILD_ROOT}

# Call the make default target which builds OpenPegasus and deploys the
# OpenPegasus image to the local Docker repository
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["make"]
