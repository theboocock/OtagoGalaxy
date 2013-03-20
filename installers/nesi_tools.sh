#!/bin/bash
# Installs the nesi tools for galaxy
#

# set the path to you local Nesi_Tools file
NESI_TOOL_PATH=/home/jamesboocock/NeSI_Tools/bin
#set the galaxy home folder
GALAXY_HOME_FOLDER=~/work/galaxy-central


echo $NESI_TOOL_PATH
OTAGO_GALAXY_LOCATION=`pwd`
echo "Installing Nesi Tool"
echo "Installing python modules."
mkdir -p $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi_scripts
cat nesi/nesi_scripts/submit_job.py | sed  "s|DEFAULT_PATH|${NESI_TOOL_PATH}|">| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi_scripts/submit_job.py
cat nesi/nesi_scripts/check_jobs.py | sed "s|DEFAULT_PATH|${NESI_TOOL_PATH}|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi_scripts/check_jobs.py
cat nesi/nesi_scripts/get_results.py| sed "s|DEFAULT_PATH|$NESI_TOOL_PATH|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi_scripts/get_results.py
cat nesi/nesi_scripts/stop_job.py   | sed "s|DEFAULT_PATH|$NESI_TOOL_PATH|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi_scripts/stop_job.py
cat nesi//nesi.py       | sed "s|DEFAULT_PATH|$NESI_TOOL_PATH|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi.py
chmod 755 $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi_scripts/*
#cp nesi/config.py     $GALAXY_HOME_FOLDER/lib/galaxy/
echo "Installing universe default nesi config your original config\
     was moved to universe_wsgi.ini.backup"
#mv $GALAXY_HOME_FOLDER/universe_wsgi.ini $GALAXY_HOME_FOLDER/universe_wsgi.ini.backup
#cp $OTAGO_GALAXY_LOCATION/nesi/universe_wsgi.ini $GALAXY_HOME_FOLDER/universe_wsgi.ini

echo "Nesi Installed reboot your galaxy instance to watch the magic work"
