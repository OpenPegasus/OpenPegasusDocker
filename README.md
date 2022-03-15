# OpenPegasus Docker Container

## Introduction

This repository contains the docker files and makefiles to create build docker
images for:

* Building an OpenPegasus build image ( the build image) in which an OpenPegasus
  wbem server run image can be built. This image is based on Ubuntu  with the
  Dockerfile, and Makefile to actually get OpenPegasus from the the github
  repository, build it, clean up the results and test the created OpenPegasus,
  and build a new image (OpenPegasusServer) that contains a runnable
  OpenPegasus executable with CIM repository, etc.
* Built OpenPegasus in a container such that OpenPegasus WBEM server starts
  and runs when a Docker container is started from this image.

OpenPegasus is an implementation of DMTF's Storage Management Initiative (SMI)
Common Information Model (CIM) Server. The source code for OpenPegasus is
contained in the OpenPegasus repository of this OpenPegasus project.

Build and run images are stored in the Docker repository kschopmeyer and
can be freely downloaded.

STATUS: Initial limited release 0.1.1.

## Requirements

The following must be present prior to building images.

* Docker version 19.x.x or later
* SSH keys that allow access to GitHub and the OpenPegasus github repository

## How to Build the Images
Building the OpenPegasus WBEM Server image is a two step process which first
requires building the server build image and then the server image.  Building the
build image can be skipped though if you choose to use one of the published
images.

The server build image builds the OpenPegasus WBEM server by compiling and
testingthe source code from the OpenPegasus/OpenPegasus repository.

### How to Build the WBEM Server Build Image
To build the docker image for building the OpenPegasus WBEM Server image first
set the docker image version in the version.txt file.  Next execute the
following build command.

```console
make build
```
This will lint the Dockerfile and then build the basic image provided no linting errors were found.

This image will contain the make file makefile_wbem-build which is the file that
defines the download

The WBEM Build makefile supports the following targets.

```
make lint     Lint the Dockerfile.
make build    Build the build image.
make deploy   Deploy, push the build image to an image registry.
make clean    Remove the build image from the local machine.
```

### How to Build the OpenPegasus WBEM Server Image
Using the build image the server image can now be built.  Run the following
command line.

```console
sudo $PWD/make run_build_server
sudo docker run -it --rm -v /home/$USER/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock smi-build:tag /bin/bash
```

You will be presented with a bash command prompt with the SMI root directory as
the current working directory.  At the prompt you are now able to execute the
following make commands.

```
make          Same as "make all"
make all      Build and publish a server image
make build    Build the server image
make test     Run tests against the built server
make publish  Build the server, a server image and push the image to an image registry
make clean    Remove build output, build image and server images
```

"make build" : clones the current OpenPegasus project, starts a build and runs the pegasus tests against the built server.

"make publish": perform all the above build tasks plus builds an wbem-server image which is presently pushed to a private image registry.

The same build tasks can also be specified on the docker command line as shown below.

```console
sudo docker run -it --rm -v /home/<username>/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock smi-build:tag "make build"
```

The container will terminate though after it finishes executing the specified command.

To only build, test and create the server image run these commands in build image bash shell.

```console
make build
make docker-build-server-image
```

The make command for the build server image will build the server image smi-server:0.1.2 on your local machine.

**Note:** At this time the tag can only be changed in the makefile.

If you wish to skip this step you can use one of the existing build images such as this one on Dockerhub.

```
peterlamanna/smi-build:0.1.0
```

## How to Run the Server Image

To run the server simply execute this command line.

```console
sudo docker run -it --rm -p 127.0.0.1:5988:5988 -p 127.0.0.1:5989:5989 smi-server:0.1.2 /bin/bash
```

or to load the server image and start OpenPegasus when the server starts enter the run command
without the last parameter ("/bin/bash")

```console
sudo docker run -it --rm -p 127.0.0.1:5988:5988 -p 127.0.0.1:5989:5989 smi-server:0.1.2
```


Again, the bash shell will have the SMI root directory as the current working
directory.  From there you can execute any cimserver of cimcli command.  To
start the server simply execute the following.

```console
cimserver
```

The server will start and print out to the console that it is listening on the default ports 5988 (http) and 5989 (https).

## Frequently asked questions
Please see [FAQ.md](./FAQ.md) for frequently asked questions.

## Source Code

* <https://github.com/OpenPegasus/OpenPegasusDocker.git>

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
