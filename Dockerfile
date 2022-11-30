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
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    openssl \
    docker.io \
    build-essential \
    ack-grep \
    git \
    tmux \
    curl \
    vim \
    libssl-dev \
    libpam0g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Build configuration variables

# Docker registry
ENV DOCKER_REGISTRY=kschopmeyer

# OpenPegasus Server name and version
ENV SERVER_IMAGE="openpegasus-server"
ENV SERVER_IMAGE_VERSION="0.1.2"

# Default definition of tests to run.  alltests runs both the unit and
# server tests. If a simpler subset of tests is to be used, that name
# can replace alltests. See pegasus Makefile and TestMakefile for more
# information on pegasus test targets
ENV PEGASUS_TEST_TARGET="alltests"

# Git Repository name, branch name and tag to checkout for the OpenPegasus build
# Use http to clone repository because no authentication required. Either the
# tag or branch define what to clone. The default is to clone main
# If PEGASUS_GIT_TAG set, only that tagged branch is cloned.  This can be use
# to build with tagged OpenPegasus releases. This must be used to build a
# container with a released pegasus version.
# If PEGASUS_GIT_BRANCH is set, the complete git repository is cloned and
# the git checkout command used to activate the defined branch. This can be
# useful for testing OpenPegasus in a container
ENV PEGASUS_GIT_TAG="v2.14.3"
ENV PEGASUS_GIT_BRANCH=""
ENV PEGASUS_GIT_REPOSITORY=http://github.com/OpenPegasus/OpenPegasus.git

#
# Define environment variables for the Pegasus file paths
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

################################################################
# TODO: Remove all the following variables from this file. They are correctly
# defined in the pegasus_build.env file and that file is attached to the
# build container when the container is started. For the moment they are
# commented out until testing is complete.

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

#ENV PEGASUS_USE_DEFAULT_MESSAGES=true

# The run container can be build to service both HTTP and HTTPS or just one
# these connection types
# Define the connection and pegasus security environment including
# ssl, pam, and pegasus usergroup

# If set, a version of OpenPegasus that supports SSL (i.e., https) is built.
#ENV PEGASUS_HAS_SSL=true

# TODO clarify this env var
#ENV OPENSSLHOME_=/usr

# Enables support for PAM-(Pluggable Authentication Modules) based authentication.
# Default is false
#ENV PEGASUS_PAM_AUTHENTICATION=true

# Builds a version of OpenPegasus that allows an administrator to restrict access
# to CIM operations to members of a designated set of groups.  Refer to the
# authorizedUserGroupsconfiguration option for additional details. Default if
# not set is not set
# ENV PEGASUS_ENABLE_USERGROUP_AUTHORIZATION=true

# When this environment variable is set, processing of ExecQuery operations is
# enabled. When not set, ExecQuery operation requests get a NotSupported response.
#ENV PEGASUS_ENABLE_EXECQUERY=true

# When this variable is set to false, support for Indication Subscription filters
# that have CQL as the language is disabled. It does not remove CQL from the build.
#ENV PEGASUS_ENABLE_CQL=true

# Enable the provider manager for providers that use the CMPI interface
# from providers to the OpenPegasus server
# If set to true, the CMPI_Provider manager is created and cmpi providers
# included in the test environment. Default is true
#ENV PEGASUS_ENABLE_CMPI_PROVIDER_MANAGER=true

# TODO
#ENV PEGASUS_ENABLE_AUDIT_LOGGER=true

# If set, OpenPegasus will be built to send log messages to the system logger
# (syslog). Otherwise, log messages will be sent to OpenPegasus specific log files.
#ENV PEGASUS_USE_SYSLOGS=true

# This variable is used for configuring the Interop namespace name. This option
# helps to establish a consistent Interop Namespace as mentioned in DMTF
# specification.(DSP1033)
# If set it defines the name for the interop namespace. The allowed
# values are root/PG_Interop, root/interop or interop.  The default interop namespace if
# this not set is root/PG_Interop.
# Note: Only limited pegasus internal tests can be run if
# the interop namespace is not set to root/PG_Interop since some test verification
# depends on the specific stringroot/PG_Interop
#ENV PEGASUS_INTEROP_NAMESPACE=root/PG_Interop

#
#  Debug and trace control variables
#
# Debug build options
# Enable the compiler debug mode which provides additional internal tests
# of the server and some displays. Default is false
#PEGASUS_DEBUG=false

# The following variable set to true reduces size by not including some
# information in the trace output.  TODO: This may not be documented in
# the options document. Default is false
# ENV PEGASUS_NO_FILE_LINE_TRACE=true
# Enable the trace facility in the pegasus client code. Default is false
#PEGASUS_CLIENT_TRACE_ENABLE=true
# Causes compiler to remove all PEGASUS_ASSERT statements. default is false
# TODO test
#PEGASUS_NOASSERTS=false

# If true, the CIM Server is compiled without method enter and exit trace statements.
# Trace Level 5 will continue to be accepted as a valid trace level but, without the
# method enter and exit trace statements, it will be equivalent to Trace Level
# 4. If PEGASUS_REMOVE_METHODTRACE is false or not set, method enter and exit trace
# statements are included.  All other values are considered invalid and will result in a build error.
# ENV PEGASUS_REMOVE_METHODTRACE=true

# The following variable set to true reduces size by not including some
# information in the trace output.  TODO: This may not be documented in
# the options document. Default is false
# ENV PEGASUS_NO_FILE_LINE_TRACE=true

# Enable the trace facility in the pegasus client code. Default is false. This does
# not affect the server.
ENV PEGASUS_CLIENT_TRACE_ENABLE=true

# Causes compiler to remove all PEGASUS_ASSERT statements. default is false
# TODO test
# ENV PEGASUS_NOASSERTS=true

#  This variable defines the default mode used to create repositories that
# are constructed as part of the automated build tests.  It does not affect the
# runtime environment. Valid values include: XML (causes the repository to be
# built in XML mode); BIN (causes the repository to be built in binary mode).
# Use cimconfig to modify the runtime environment.
# We use BIN because it is significantly smaller than XML and faster
#ENV PEGASUS_REPOSITORY_MODE=BIN

# If set the Repository Compression logic is built and enabled and compressed
# and non compressed repositories are supported. If not set then compressed
# repositories are not supported.
# NOTE: Setting this variable  requires an extra library and header file for zlib.
#ENV PEGASUS_ENABLE_COMPRESSED_REPOSITORY=true

# Define repository version.  This is used at least for development builds
# and installs the DMTF schema defined and available in the directory
# pegasus/schemas into the namespaces. NOTE: schemas must be installed
# in that directory with the instructions in that directory to be compilable
# through the pegasus make repository command.
# If not defined, the default is DMTF  schema  version 2.41
#
# ENV PEGASUS_CIM_SCHEMA=CIM241

# If true, new repository stores are created using a SQLite database. Existing
# file-based stores will continue to be recognized and operate seamlessly.
# If PEGASUS_USE_SQLITE_REPOSITORY is set to true and SQLite files are not
# installed in default search locations, SQLITE_HOME must also be configured.
# PEGASUS_REPOSITORY_STORE_COMPLETE_CLASSES may not be set to true when
# PEGASUS_USE_SQLITE_REPOSITORY is set to true.
# ENV PEGASUS_USE_SQLITE_REPOSITORY=true

# If set to true, this variable can be used to reduce the time required to
# build OpenPegasus by significantly reducing the number of tests that are built.
# Setting this variable to true affects the behavior of all recursive make targets
# (e.g., clean, depend, all, unittests, alltests, and slptests). Use of this
# variable with test-related targets (e.g., unittests, alltests and slptests)
# can produce unexpected results. To avoid creating an inconsistent PEGASUS_HOME
# directory, the PEGASUS_HOME directory (i.e., the OpenPegasus build directory)
# should be removed prior to enabling or disabling this variable.
# TODO test this before using
# ENV PEGASUS_SKIP_MOST_TEST_DIRS=true

# This variable is used to enable a set of workarounds that support the use of
# OpenPegasus in the SNIA Test Environment.
# Defined a specific change to WQL parser for SNIA testing. This allows
# dotted property names. Default is to not set this.
# This is considered experimental and for WQL only.
# ENV PEGASUS_SNIA_EXTENSIONS=true

# END OF COMMENTED OUT ENV statements.

# Add the Makefile and Dockerfile for building the server image based on
# the build image
COPY ./Makefile_wbemserver-build ${PEGASUS_BUILD_ROOT}/Makefile
COPY ./Dockerfile_wbemserver-build ${PEGASUS_BUILD_ROOT}/Dockerfile

# OpenPegasus Build folder
WORKDIR ${PEGASUS_BUILD_ROOT}

# Build the OpenPegasus binaries and test the cimserver
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["make build"]
