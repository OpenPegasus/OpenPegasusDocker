#
# This shell script executes a full build and test of OpenPegasus whereas
# the  corresponding Makefile  test target only executes a limited test.
# To accomplish that, it sets the namespace to root/PG_InterOp independent
# of what was set by the container and also may set different make variables
# to maximize testing
# Since this possibly modifies build environment variables it is executed as
# an independent script to assure that the modified pegasus config variables
# do not get inserted into any build. Note that it does not remove the created
# object/executeable files that would go into the build.
#
# This script assumes that the make build has already been executed.
#
echo "The original configuration env variables for this build are:"
export | grep PEGASUS
echo
export OpenPegasusNamespace="root/PG_InterOp"
cd OpenPegasus/pegasus
echo "Execute the OpenPegasus make world"
make world
