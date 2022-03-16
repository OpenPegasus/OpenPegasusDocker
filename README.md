# OpenPegasus Docker Container builder

[![Linux](https://svgshare.com/i/Zhy.svg)](https://svgshare.com/i/Zhy.svg)

# [![GitHub version](https://badge.fury.io/gh/Naereen%2FStrapDown.js.svg)](https://github.com/Naereen/StrapDown.js)

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

[![Docker](https://badgen.net/badge/icon/docker?icon=docker&label)](https://https://docker.com/)

## Introduction

This repository contains the docker files and makefiles to create build docker
images for:

* Building an OpenPegasus build image ( the build image) in which an OpenPegasus
  wbem server run image can be built. This image is based on Ubuntu  with the
  Dockerfile, and Makefile to actually get OpenPegasus from the the github
  repository, build it, clean up the results and test the created OpenPegasus,
  and build a new image (OpenPegasusServer) that contains a runnable
  OpenPegasus executable with CIM repository, etc.
* Building OpenPegasus in a container such that OpenPegasus WBEM server starts
  and runs when the Docker container is started from this image.

OpenPegasus is an implementation of DMTF's Storage Management Initiative (SMI)
Common Information Model (CIM) Server. The source code for OpenPegasus is
contained in the OpenPegasus repository of this OpenPegasus project.

Build and run images are stored in the Docker repository defined in the
Dockerfile (currently the docker repository kschopmeyer) and can be freely downloaded.

STATUS: Limited release 0.1.2.

## Requirements

The following must be present prior to building images.

* Docker version 19.x.x or later
* SSH keys that allow access to GitHub and the OpenPegasus github repository

## How to Build the Images
Building the OpenPegasus WBEM Server image is a two step process:

1. Building the server build image which starts with a Linux image (Ubuntu) and
adds the tools and variables to be able to checkout the OpenPegasus source code
and build OpenPegasus from within that build container.

2. Running the build container which includes targets for checking out OpenPegasus source code,
building OpenPegasus, testing OpenPegasus, and creating the OpenPegasus run image with just
the runtime components of OpenPegasus and whatever provisioning choices you have made.
OpenPegasus must be provisioned with any required providers and CIM Model components
for the target environment.  The default is to build the server with the OpenPegasus
test environment that includes an number of providers and a CIM repository
based on a DMTF released schema.

### How to Build the WBEM Server Build Image
To build the docker image for building the OpenPegasus WBEM Server image first
set the docker image version in the version.txt file.  Next execute the
following build command.

```console
make build
```
This will lint the Dockerfile and then build the basic image provided no
linting errors were found.

This image will contain the make file Makefile_wbem-build (renamed to Makefile) which is the file that
defines the download.

The WBEM Build makefile supports the following targets.

NOTE: The lint will only occur if the docker lint tool TODO is installed.

```
make lint     Lint the Dockerfile.
make build    Build the build image.
make deploy   Deploy, push the build image to an image registry.
make clean    Remove the build image from the local machine.
```

### How to Build the OpenPegasus WBEM Server Image
Using the build image the server image can now be built.

Building the OpenPegasus WBEM Server Image involves:
1. Retrieving the OpenPegasus Source code, etc. from github OpenPegasus repository
2. Building OpenPegasus from this source code.
   1. Since the build process for OpenPegasus involves setting a number of
      environment variables that control the build, A set of these variables
      is defined in the Dockerfile.
   2. Running tests on the build OpenPegasus code to confirm that the build
      was executed properly.
   3. Cleaning unwanted components out of the build result to minimize the
      built image. This includes removing the intermediate build components,
      the OpenPegasus source package, the test files and other temporary
      components.
   4. Provisioning the WBEM server with a CIM model and possibly building and
      installing providers for the target environment.

Run the following command line.

```console
sudo make start-build-container

# The build container start can also be done with the following docker command:
  sudo docker run -it --rm -v /home/$USER/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock smi-build:tag /bin/bash
```

You will be presented with a bash command prompt with the SMI root directory as
the current working directory.  At the prompt you are now able to execute the
following make commands.

```
  make lint                    Lint the Dockerfile.
  make build                   Build the build image.
  make deploy                  Deploy, push the build image to a docker image registry.
  make clean	                Remove the build image from the local machine.
  make start-build-container	Run the build the pegasus server image.
  make start-run-container	    Run OpenPegasus WBEM server in container
                                with default HTTP and HTTPS ports
```

A logical sequence to build the

"make build" : clones the current OpenPegasus project, starts a build and runs
the pegasus tests against the built server.

"make deploy": perform all the above build tasks plus builds the wbem-server
image which is presently pushed to a private image registry.

The same build tasks can also be specified on the docker command line as shown below.

```console
sudo docker run -it --rm -v /home/<username>/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock smi-build:tag "make build"
```

Adding /bin/bash at the end of the command causes the server to start at the bash
console interface rather than automatically executing make build and it the default

The container will terminate though after it finishes executing the specified command.

To only build, test and create the server image from within the build container run these commands in build image bash shell.

```console
make build
make deploy
```


TODO

The make command for the build server image will build the server image smi-server:0.1.2 on your local machine.

If you wish to skip this step you can use one of the existing build images
such as this one on Dockerhub.

The OpenPegasus public build image build by this set of utilities is:

```
kschopmeyer/openpegasus-build:0.1.1
```

The corresponding image for the running server is:

```
kschopmeyer/openpegasus-server:0.1.1
```

NOTE: Currently the build and server image are in a user repository kschopmeyer
awaiting Docker approval of a public repository to be named OpenPegasus.

```
kschopmeyer/openpegasus-build:0.1.1
```

## How to Run the Server Image

To run the server simply execute this command line.

```console
sudo docker run -it --rm -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 kschopmeyer/openpegasus-server:0.1.2 /bin/bash

```

or the make target start-run-container.

or to load the server image and start OpenPegasus when the server starts enter the run command
without the last parameter ("/bin/bash")

The above command starts the server

```console
sudo docker run -it --rm -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 smi-server:0.1.2
```

The bash shell will have the SMI root directory as the current working
directory.  From there you can execute any cimserver or cimcli commands.  To
start the server simply execute the following.

```console
cimserver
```

And to stop the server and return to the container console:

```console
cimserver -s
```
The server container will go through a shutdown process and return to the
console interface.

The server will start and print out to the console that it is listening on the default ports 5988 (http) and 5989 (https).


## Configuration of OpenPegasus in the run image

The default run server has the following characteristics as defined by the
variables in the the server build Docker file (Docker file in the repository)

1. Both https and http available. The default defined in Dockerfile is
port 15988 for http and 15989 for https.

2. A set of locally define  certificates

3 The CIM repository is based on what has been built into the OpenPegasus source
repository for testing.  Currently
it is the CIM repository for CIM Schema 2.41.0 and a set of extensions for
testing OpenPegasus including a number of classes and corresponding pegasus
test providers.  This is scattered over a number of CIM namespaces including
an Interop namespace root/interop.

4. OpenPegasus wbem server so that once the server is running in the run
container, overall information on the server can be viewed on the containers
URI and OpenPegasus ports

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
