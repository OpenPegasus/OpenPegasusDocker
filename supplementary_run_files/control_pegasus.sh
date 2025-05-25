#
# This bash script starts OpenPegasus as part of the  pegasus run container
# startup process.  It is called by the Dockerfile RUN command
# Specific changes to the startup process are determined by the value of
# one or more environment variables that are defined in the pegasus
# run environment.
#

# start the openpegasus cim server
echo "Start OpenPegasus"
cimserver
echo "OpenPegasus stopped."
