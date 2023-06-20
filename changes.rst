# OpenPegasus Docker Change log

##Change log

## OpenPegasusDocker 0.1.3 - Release

Status: **Released 21 Aug. 2023*

### Bugs
1. Errors in the logic to assign the START_MODE for the build and server
   containers.  Fixed.

### Enhancements

### Cleanup

1. Change the container name to openpegasus
2. Several minor cleanups.
3. Clean up README
4. Added new directory to be passed on to server container. This
   directory is named supplementary_run_files and can contain
   other files to be used in the running server container.
5. Added more tools to the build image.  Since there is no major
   issue with the size of this container, additional test and
   develop files are not important. For the moment it only contains
   the file send_indication.sh which can be used from the container
   to test sending indications to a pywbemlistener.
6. Change name of Makefile_wbemserver-build to add suffix of .mak
7. Set version to 0.1.3
8. Created attic directory and moved some obsolete files to that directory.


## OpenPegasusDocker 0.1.2 - Release

Status: **Released**

Release Date:  December 2022

branch: main

### Bugs

### Enhancements

Rewrote the Docker files and make files to accomplish the following:

1. Move the OpenPegasus build variables from Docker file to a file that is
   passed to the Docker build run command (pegasus-build-vars.env). Thus,
   pegasus build environment variables are attached to the the build image when
   the image is run rather than when the image is build.  This includes
   the environment variables that control the compile and test of OpenPegasus
   and variables that control the git clone of the OpenPegasus source code, and
   variables that control the directories for OpenPegasus clone, and build.

   Note that there are a few environment variables defining the build container.
   Build directory defintions and the pegasus platform environment variable
   remain in the Docker file.

2. Greatly expanded the number of environment variables available to the build
   in the new pegasus_build.env file and documentation for each of these
   variables.

3. Expanded the number of targets in the Makefile and the wbemserver-make-file
   to include more targets to make building and testing pegasus in the container
   simpler and more granular.  Note that there is help for the Makefile
   targets for both the build and run make files using `make help`

4. Change the make files to separate targets for deploy (create the local
   image) from publish (push the locall image to the Docker repository). Deploy
   creates a local image and publish pushes the image to the Docker repository
   This is because we consider the publish of the
   build and server containers as separate from the deploy/build of these
   containers. Note that when published both containers get tagged with the
   repository name in addition to the container name and version.

4. Add publish-server-image to Dockerfile so that it does not have to be done
   within the build container.

5. Add environment variables so that OpenPegasus can be retrieved from the
   git repository based on either git tag (i.e. a release) or on a branch
   where the main branch is the default.  This allows building OpenPegasus
   image from either a release tag version or from a development branch.

6. Add .done files to the make files so that there is a signal for each of the
   steps executed.

7. Rewrote much of the README.md documentation to document the new and changed
   features of this git repository.

9. Added capability to run the build process for both the build image and the
   server image either completely automatically from end to end or manually
   where a bash terminal is started when the image starts.  This allows a
   build or run container to execute it default targets and close without user
   interaction (automatic) or to have the user manually execute the make
   targets.  Thus normally the run of the build container is manual so that
   the user can control the build and deploy process but the th run of the
   openpegasus-server container is automatic starting the OpenPegasus WBEM
   server when the container is started.  The environment variables for this
   are BUILD=<auto or bash> and RUN <auto or bash>.

### Cleanup

1. Cleanup the comments in all of the files.

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
