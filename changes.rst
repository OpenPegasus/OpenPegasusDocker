# OpenPegasus Change log

##Change log

## OpenPegasusDocker 0.1.2 - Release

Status: **Development**

Release Date:

branch: main

### Bugs

### Enhancements

Rewrote the Docker files and make files to accomplish the following:

1. Move the build variables from Docker file to a file that is passed to the
   docker build run command (pegasus_build.env). Thus, pegasus build
   environment variables are attached to the the build image when the image is
   run rather than when the image is build.

   Note that there are a few environment variables defining the build container
   build directories and the pegasus platform remain in the Docker file.

2. Greatly expanded the number of environment variables available to the build
   in the new pegasus_build.env file

3. Expanded the number of targets in the Makefile and the wbemserver-make-file
   to include more targets to make building and testing pegasus in the container
   simpler.

### Cleanup

906 288 381

107 853 16
877 256 1640 ext 1131234



## OpenPegasusDocker 0.1.1 - Release

Status: **Released**
branch: main

This version of OpenPegasusDocker creates a minimal version of a running
OpenPegasus Docker container that runs as part of the pywbemtools test suite.

It was build using OpenPegasus 14.2 but the lastest version of the main
rather than a release tag.

It is committed as a release tag because it is the current container version
committed to the docker repository kschopmeyer as

kschopmeyer/openpegasus-server:0.1.1
