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

## Building the Docker images

### Building the Docker build image

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

OpenPegasus must be provisioned with providers and CIM Model
components in a repository for the target environment.  The default is to build
the server with the OpenPegasus test environment that includes an number of
providers and a CIM repository based on a DMTF released schema.

### Build the OpenPegasus Docker build image
To build the docker image for building the OpenPegasus WBEM Server image
execute the following build command.

```console
make build
```
This will lint the Dockerfile (if docker lint was installed in the host system)
and then build the basic image provided no linting errors were found.

This image will contain the make file Makefile_wbem-build (renamed to Makefile
when the build image is created) which is the file that defines the targets for
building the OpenPegasus WBEm server from its source code.

The WBEM Build makefile supports the following targets and a number of subtargets
that are listed with Makefile help

NOTE: The lint will only occur if the docker lint tool is installed.

```
make lint                   Lint the Dockerfile.
make build                  Build the build image.
make deploy                 Build the run image.
make publish                Publish the build image to the remote docker repository.
make clean                  Remove the build image from the local machine.
make run-build-image        Run the build the docker pegasus server image."
make run-server-image	    Run OpenPegasus WBEM server docker image"
```

### Build the OpenPegasus WBEM Server Image

Using the build image the server run image can now be built.

Building the OpenPegasus WBEM Server image involves the following steps run within
the build container:
1. Retrieving the OpenPegasus source code from github OpenPegasus repository
2. Building OpenPegasus from this source code.
   a. Since the build process for OpenPegasus involves setting a number of
      environment variables that control the build, A set of these variables
      is defined in the file `pegasus_build_vars.env` which is attached to the
      build build image when that image is run (`--env-file` option)
   b. Running tests on the build OpenPegasus code to confirm that the build
      was executed properly.
   c. Cleaning unwanted components out of the build result to minimize the
      built image. This includes removing the intermediate build components,
      and most of the test executables/files and other temporary components.
   d. Provisioning the WBEM server with a CIM model and possibly building and
      installing providers for the target environment.

An OpenPegasus WBEM server image can be created by just running the
following:

1. Clone this repository to your local machine
2. Create the build image which consists of Ubuntu Linux OS, updates to Ubuntu and
   build tools to compile OpenPegasus source code and a Makefile that
   defines the build, test, and deploy of an OpenPegasus Docker image
   (`make build').
3. Run the build container (`make run-build-image`). The Makefile option
   BUILD-START-MODE defines whether the process to build the WBEM server image
   is automatic or manual.
4. Move to the terminal started when the build image  is started if the manual
   execution of the build process (default mode) was defined.
5. Build the OpenPegasus WBEM server (`make build`).
6. Deploy the OpenPegasus server container (`make deploy`).
7. Return to the the original terminal window.
8. Start the OpenPegasus WBEM server run image (make run-server-image).
9. The WBEM server should be running in its Docker container.  This can be
   tested by:
   a. View the WEB page displayed by the container at the same ports as its
      XML ports (default 15988 and 15989)
   b. Run a WBEM client against the server at either of the ports (for example
      run the pywbemtools client)
   c. Test that the ports are open

### Running the OpenPegasus WBEM Server Image

The OpenPegasus WBEM server may be started when the openpegas-server images is
started with the make file option SERVER-START-MODE as follows:

```console
make run-server-image SERVER-START-MODE=manual
```

Thus the set of commands below will create and run an OpenPegasus server container:

```console
git clone https://github.com/OpenPegasus/OpenPegasusDocker.git
make build
make run-build-container
# Go to the console in the running build container
make build
make deploy
# exit the build container and start the pegasus run container
make run-server-container

```

Or to automatically execute the whole process from the console:

```console
git clone https://github.com/OpenPegasus/OpenPegasusDocker.git
make build
make run-build-container BUILD_STARTUP_MODE=auto
# When the new WBEM server image has been built.
make run-server-image
# The server container will be started and the OpenPegasus WBEM server
will be running within that container.

```

The build container start can also be done with the following docker command:
sudo docker run -it --rm -v /home/$USER/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock openpegasus-build:tag /bin/bash

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

`make build` : clones the current OpenPegasus project, starts a build and runs
the pegasus tests against the built server.

`make deploy`: performs all the above build tasks plus builds the pegasus WBEM server

The same build tasks can also be specified on the docker command line as shown below.

The build command requires a file containing the definition of environment variables
that configure the built WBEM server. These environment variables are passed to the build container
with the  --env-file option. A default
environment file (pegasus-build-vars.env) is part of this repository.

```console
sudo docker run -it --rm -v /home/<username>/.ssh:/root/.ssh --env-file -v /var/run/docker.sock:/var/run/docker.sock openpegasus-build:<tag> "make build"
```

Adding `/bin/bash` at the end of the command causes the server to start at the bash
console interface rather than automatically executing make build and it the default

The container will terminate though after it finishes executing the specified command.

To only build, test and create the server image from within the build container
run these commands in build image bash shell.

```console
make build
make deploy
```

The make command for the build server image will build the server image
openpegasus-server:<tag> on your local machine.

If you wish to skip this step you can use one of the existing build images
such as this one on Dockerhub.

NOTE: Currently the build and server image are in the docker user repository `kschopmeyer`.

The OpenPegasus public build image build by this set of utilities is:

```
kschopmeyer/openpegasus-build:0.1.2
```

The corresponding image for the running server is:

```
kschopmeyer/openpegasus-server:0.1.2
```

## Run the OpenPegasus WBEM Server Image

### Start the WBEM Server container using the makefile

To start OpenPegasus in the server container from the make file defined in
this github repository  and start OpenPegasus in the container on startup:

```console
make run-server-image

```
or to start the server container but not start OpenPegasus when the
container starts:

```console
make run-server-image SERVER-START-MODE=manual

The bash shell will have the directory containing pegasus components root
directory as the current working directory.  From there you can start the
OpenPegasus server (`cimserver` to start the server as a daemon ) and
still have a console for terminal commands such as a quick test of the
server (`cimcli ns`)To start the OpenPegasus server when the the server container
was started in manual mode simply execute the
following:

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

The command line "docker stop pegasus" command can be used to shut down the server container
will go through a shutdown process and return to the console interface.

The server will start and print out to the console that it is listening on the
ports 15988 (http) and 15989 (https).





### Starting the WBEM Server container directly using docker commands

To run the server simply execute the following command line. This runs the container and
starts the OpenPegasus web server in the container.

```console
sudo docker run -it --rm -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 kschopmeyer/openpegasus-server:0.1.2

```

or if using a local run image created by the build container

```console
sudo docker run -it --rm -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 openpegasus-server:0.1.2

```

or use the make target  `make run-server-container` from the clone of this git repository.

To run the server image and not automatically start OpenPegasus when the server starts enter the run command
with the last parameter ("/bin/bash")

The above command starts the server

```console
sudo docker run -it --rm -p 127.0.0.1:15988:5988 -p 127.0.0.1:15989:5989 kschopmeyer/openpegasus-server:0.1.2
```


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
   the OpenPegasus WBEM server.  Using a tool like OpenPegasus or pywbemtools, the server can
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
