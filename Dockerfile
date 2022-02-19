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
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    openssl \
    docker.io \
    build-essential \
    libssl-dev \
    libpam0g-dev \
    ack-grep \
    git \
    curl \
    openssh-client \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Pegasus file paths
ENV PEGASUS_WBEM_ROOT=/root/wbem
# PEGASUS_HOME defines the target location for pegasus builds including
# object files, executables, the repository, and security files
ENV PEGASUS_HOME=${PEGASUS_WBEM_ROOT}/home
# Defines the top level of the pegasus source files (pegasus)
ENV PEGASUS_ROOT=${PEGASUS_WBEM_ROOT}/OpenPegasus/pegasus

# Create directory structure
RUN mkdir -p ${PEGASUS_HOME} && \
    mkdir -p /root/.ssh

# Build settings
# Settings below that are flags, with values set to true, enable the action
# simply through the existance of the variable.  The variables value has no
# effect.
# See pegasus/doc/BuildAndReleaseOpetions.html for more detailed information
# on the options

# Platform defined for the docker image
ENV PEGASUS_PLATFORM=LINUX_X86_64_GNU

ENV PEGASUS_USE_DEFAULT_MESSAGES=true

# Define the connection and pegasus security environment including
# ssl, pam, and pegasus usergroup
ENV PEGASUS_HAS_SSL=true
ENV OPENSSL=/usr
ENV PEGASUS_PAM_AUTHENTICATION=true
# Enable pegasus usergroup authorization
# TODO document the usergroup authorization capability
# ENV PEGASUS_ENABLE_USERGROUP_AUTHORIZATION=true

# Query capabilities. Enable execquery and CQL
ENV PEGASUS_ENABLE_EXECQUERY=true
ENV PEGASUS_ENABLE_CQL=true

# If set to true, the CMPI_Provider manager is created and cmpi providers
# included in the test environment. Default is true
ENV PEGASUS_ENABLE_CMPI_PROVIDER_MANAGER=false

# Logging
# If true, enable the audit-logger that logs all operations that modify
# entities within the environement
ENV PEGASUS_ENABLE_AUDIT_LOGGER=true
# If set false, logs are sent to OpenPegasus specific log files.
# default is true
# ENV PEGASUS_USE_SYSLOGS=false

# Interop namespace
# If set it defines the name for the interop namespace. The allowed
# values are root/interop or interop.  The default interop namespace if
# this not set is root/PG_Interop
ENV PEGASUS_INTEROP_NAMESPACE=root/interop

# Debug build options
# Enable the compiler debug mode if the following is true. Default is false
ENV PEGASUS_DEBUG=true
# If the following is enabled, the trace code is removed from build reducint
# size. Default is false. TODO: Test this
# ENV PEGASUS_REMOVE_METHODTRACE=true
# The following variable set to true reduces size by not including some
# information in the trace output.  TODO: This may not be documented in
# the options document. Default is false
# ENV PEGASUS_NO_FILE_LINE_TRACE=true
# Enable the trace facility in the pegasus client code. Default is false
ENV PEGASUS_CLIENT_TRACE_ENABLE=true
# Causes compiler to remove all PEGASUS_ASSERT statements. default is false
# TODO test
# ENV PEGASUS_NOASSERTS=true

# Define repository version.  This is used at least for development builds
# and installs the DMTF schema defined and available in the directory
# pegasus/schemas into the namespaces. NOTE: schemas must be installed
# in that directory with the instructions in that directory to be compilable
# through the pegasus make repository command.
# If not defined, the default is DMTF  schema  version 2.41
#
# ENV PEGASUS_CIM_SCHEMA=CIM241

# Define the repository type.  OpenPegasus allows variations on the
# repository implementation for size, speed, etc.  These are define with
# the following environment variables
# Repository mode: may be XML or BIN.
# ENV PEGASUS_REPOSITORY_MODE=XML
# ENV PEGASUS_ENABLE_COMPRESSED_REPOSITORY=true
# An alternate implemenation is Sqlite as a repository.  If used it
# requires installation of sqlite and setting SQLITE_HOME. Default is false
# ENV PEGASUS_USE_SQLITE_REPOSITORY=true


# Reduce the nunber of tests executed during the test phase. This reduces
# the time to execute the test suite.
# TODO test this before using
# ENV PEGASUS_SKIP_MOST_TEST_DIRS=true
# Reduce the number of test programs built. Speeds up the build process
# ENV PEGASUS_SKIP_MOST_TEST_DIRS=true

# Defined a specific change to WQL parser for SNIA testing. This allows
# dotted property names. Default is to not set this.
# This is considered experimental and for WQL only.
# ENV PEGASUS_SNIA_EXTENSIONS=true

# Add to path for build
# TODO: This is for development build.
ENV PATH=${PEGASUS_HOME}/bin:$PATH

# Add files for building the server image
COPY ./makefile_wbem-build ${PEGASUS_WBEM_ROOT}/makefile
COPY ./Dockerfile_wbem-server ${PEGASUS_WBEM_ROOT}/Dockerfile

# Build folder
WORKDIR ${PEGASUS_WBEM_ROOT}

# Build the binaries and run the cimserver
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["make build"]
