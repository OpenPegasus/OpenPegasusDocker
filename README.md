# OpenPegasus Docker Container Builder

[![Linux](https://svgshare.com/i/Zhy.svg)](https://svgshare.com/i/Zhy.svg)


[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

[![Docker](https://badgen.net/badge/icon/docker?icon=docker&label)](https://https://docker.com/)

## Introduction

This repository contains the Docker files and make files to create docker
images for:

* OpenPegasus development/build image in which an OpenPegasus
  wbem server run image can be compiled, tested, and an OpenPegasus run image
  built. This image is based on Ubuntu and the gcc toolset  with the
  Dockerfile, and Makefile to get OpenPegasus from the the github
  repository, compile and test the created OpenPegasus..
* Build OpenPegasus executable and provisioning (repository, etc) in another
  container such that the OpenPegasus WBEM server starts and runs when this run
  container Docker container is started from this image.

OpenPegasus is an implementation of DMTF's Storage Management Initiative (SMI)
Common Information Model (CIM) Server. The source code for OpenPegasus used for
these containers is contained in the OpenPegasus repository of this OpenPegasus
project.

Build and run images are stored in the Docker repository defined in the
Dockerfile (currently the docker repository kschopmeyer) and can be freely downloaded.

This set of docker configuration tools allows a significant number of options in
building the WBEM server including:

1. Choosing the git OpenPegasus version and the git branch to get the OpenPegasus source files
2. All of the OpenPegasus build options that define the built server.  These are defined
   in the file pegasus-build-vars.env with documentation for each build configuration
   parameter.  Note that by defining the build configuration variables in a separate
   file, they can be modified each time the build image is run.  The build variables
   can also be modified after the build images has started by modifying individual
   environment variables in the running build container.

STATUS: Limited release 0.1.2.

## Requirements

The following must be present prior to building images.

* Docker version 19.x.x or later

## Building the Images
Building the OpenPegasus WBEM Server image is a two step process:

1. Building the server build image which starts with a Linux image (Ubuntu) and
adds the tools and variables to be able to checkout the OpenPegasus source code
and build OpenPegasus from within that build container.

2. Running the build image container which includes Makefile targets for
   * checking out OpenPegasus source code,
   * building and testing OpenPegasus,
   * provisioning the server with a CIM repository and providers,
   * creating the OpenPegasus run image with just the runtime
components of OpenPegasus and whatever provisioning choices you have made.

OpenPegasus must be provisioned with any required providers and CIM Model
components in a repository for the target environment.  The default is to build
the server with the OpenPegasus test environment that includes an number of
providers and a CIM repository based on a DMTF released schema.

### Build the OpenPegasus Build Image
To build the docker image for building the OpenPegasus WBEM Server image first
set the docker image version in the version.txt file.  Next execute the
following build command.

```console
make build
```
This will lint the Dockerfile and then build the basic image provided no
linting errors were found.

This image will contain the make file Makefile_wbem-build (renamed to Makefile)
which is the file that defines the download.

The WBEM Build makefile supports the following targets and a number of subtargets
that are listed with Makefile help

NOTE: The lint will only occur if the docker lint tool  is installed.

```
make lint     Lint the Dockerfile.
make build    Build the build image.
make deploy   Build the run image.
make publish  Publish the build image to the remote docker repository.
make clean    Remove the build image from the local machine.
```

### Build the OpenPegasus WBEM Server Image
Using the build image the server run image can now be built.

Building the OpenPegasus WBEM Server image involves the following steps run within
the build container:
1. Retrieving the OpenPegasus Source code, etc. from github OpenPegasus repository
2. Building OpenPegasus from this source code.
   1. Since the build process for OpenPegasus involves setting a number of
      environment variables that control the build, A set of these variables
      is defined in pegasus_build_vars.env.
   2. Running tests on the build OpenPegasus code to confirm that the build
      was executed properly.
   3. Cleaning unwanted components out of the build result to minimize the
      built image. This includes removing the intermediate build components,
      and most of the test executables/files and other temporary components.
   4. Provisioning the WBEM server with a CIM model and possibly building and
      installing providers for the target environment.

An OpenPegasus WBEM server image can be created by just running the
following:

1. Clone this repository to your local machine
2. Create the build image which consists of Ubuntu, updates to Ubuntu and
   build tools to compile OpenPegasus source code
3. Run the build container an build OpenPegasus
4. Deploy the OpenPegasus server container

Thus the set of commands below will create an OpenPegasus server container:

```console
git clone https://github.com/OpenPegasus/OpenPegasusDocker.git
make build
make run-build-container
# go to the console in the running build container
make build
make deploy
# exit the build container and start the pegasus run container
make run-server-container

```

The build container start can also be done with the following docker command:
sudo docker run -it --rm -v /home/$USER/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock smi-build:tag /bin/bash

You will be presented with a bash command prompt with the SMI root directory as
the current working directory.  At the prompt you are now able to execute the
following make commands.

```console
  make lint                    Lint the Dockerfile.
  make build                   Build the build image.
  make deploy                  Deploy, push the build image to a docker image registry.
  make clean	               Remove the build image from the local machine.
  make run-build-container     Run the build the pegasus server image.
  make run-server-container    Run OpenPegasus WBEM server in container
                               with default HTTP and HTTPS ports
```

A logical sequence to build the server from within the build container terminal

"make build" : clones the current OpenPegasus project, starts a build and runs
the pegasus tests against the built server.

"make deploy": performs all the above build tasks plus builds the pegasus WBEM server

The same build tasks can also be specified on the docker command line as shown below.

The build command requires a file containing the definition of environment variables
that configure the built image. These environment variables are passed to the build container
with the  --env-file option. A default
environment file (pegasus-build-vars.env) is part of this repository.

```console
sudo docker run -it --rm -v /home/<username>/.ssh:/root/.ssh --env-file -v /var/run/docker.sock:/var/run/docker.sock smi-build:<tag> "make build"
```

Adding /bin/bash at the end of the command causes the server to start at the bash
console interface rather than automatically executing make build and it the default

The container will terminate though after it finishes executing the specified command.

To only build, test and create the server image from within the build container run these commands in build image bash shell.

```console
make build
make deploy
```

The make command for the build server image will build the server image openpegasus-server:<tag> on your local machine.

If you wish to skip this step you can use one of the existing build images
such as this one on Dockerhub.

NOTE: Currently the build and server image are in the docker  user repository kschopmeyer.

The OpenPegasus public build image build by this set of utilities is:

```
kschopmeyer/openpegasus-build:0.1.2
```

The corresponding image for the running server is:

```
kschopmeyer/openpegasus-server:0.1.2
```



## Run the Server Image

To run the server simply execute this command line . This runs the container and
starts the OpenPegasus web server in the container.

```console
sudo docker run -it --rm -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 kschopmeyer/openpegasus-server:0.1.2

```

or the make target  make run-server-container.

To run the server image and not automatically start OpenPegasus when the server starts enter the run command
with the last parameter ("/bin/bash")

The above command starts the server

```console
sudo docker run -it --rm -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 kschopmeyer/openpegasus-server:0.1.2
```

The bash shell will have the directory containing pegasus components root
directory as the current working directory.  From there you can execute any
cimserver or cimcli commands.  To start the server simply execute the
following.

```console
cimserver
```

And to stop the wbem server and return to the container console:

```console
cimserver -s
```

The following command will also indicate whether the server is running or not.

```console
cimserver --status
```

The running server can be accessed from within the container using the
OpenPegasus utility cimcli that has commands to execute requests on the server.

The simplest command is "cimcli ns" that displays the namespaces defined for
the wbem server and is a good indicator that the server is working correctly.

The command line "exit" command can be used to shut down the server container will go through a shutdown process and return to the
console interface.

The server will start and print out to the console that it is listening on the
default ports 5988 (http) and 5989 (https).

## Configuration of OpenPegasus in the run image

The default run server (define with the pegasus-build-vars.env file) has the
following characteristics as defined by the variables in the the server build
Docker file (Docker file in the repository)

1. Both https and http available. The default defined in Dockerfile is
port 15988 for http and 15989 for https.

2. A set of locally define SSL  certificates

3 The CIM repository that is based on what has been built into the OpenPegasus source
repository for testing.  Currently it is the CIM repository for CIM Schema
2.41.0 and a set of extensions for testing OpenPegasus including a number of
classes and corresponding pegasus test providers.  This is scattered over a
number of CIM namespaces including an Interop namespace root/PG_InterOp.

4. OpenPegasus wbem server so that once the server is running in the run
container, overall information on the server can be viewed on the containers
URI and OpenPegasus ports

5. The OpenPegasus web server which allows remotely viewing and modifying
characteristics of the server running at http://localhost:15988

## Frequently asked questions
Please see [FAQ.md](./FAQ.md) for frequently asked questions.

1. Does this container work like most WBEM servers.
   Yes.  It is a full OpenPegasus implementation except that rather than having
   a model implementation that strictly adheres to to a DMTF or SMI profile, it
   contains components of these models that are used for testing the intrigity of
   the server.  Using a tool like OpenPegasus or pywbemtools, the server can
   be explored from either a console attached to the container or directly
   through the CIM/XML interface using the ports that have been defined for the
   server in the startup command.

## Source Code

* OpenPegasusDocker <https://github.com/OpenPegasus/OpenPegasusDocker.git>
* OpenPegasus <https://github.com/OpenPegasus/OpenPegasus.git>


## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Keyport Technologies, Inc. | support@keyporttech.com | https://keyporttech.github.io/ |
| Inova Developement, Inc.   | k.schopmeyer@gmail.com  | https://github.com/OpenPegasus |

## Contributing

We welcome both companies and individuals to provide feedback and updates to
this repository.

## Copyright
Copyright (c) 2020 Keyport Technologies, Inc. All rights reserved.
Copyright (c) 2021 Inova Development Inc. All rights reserved.
