#!/bin/bash
# Installs the nesi tools for galaxy
#

# set the path to you local Nesi_Tools file
NESI_TOOL_PATH=/home/sfk/Podcasts/NeSI_Tools/bin

echo $NESI_TOOL_PATH
OTAGO_GALAXY_LOCATION=`pwd`
echo "Installing Nesi Tool"

echo "Installing python modules."
cat nesi/submit_job.py | sed  "s|DEFAULT_PATH|${NESI_TOOL_PATH}|">| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/submit_job.py
cat nesi/check_jobs.py | sed "s|DEFAULT_PATH|${NESI_TOOL_PATH}|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/check_jobs.py
cat nesi/get_results.py| sed "s|DEFAULT_PATH|$NESI_TOOL_PATH|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/get_results.py
cat nesi/stop_job.py   | sed "s|DEFAULT_PATH|$NESI_TOOL_PATH|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/stop_job.py
cat nesi/nesi.py       | sed "s|DEFAULT_PATH|$NESI_TOOL_PATH|" >| $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/nesi.py
cp nesi/config.py     $GALAXY_HOME_FOLDER/lib/galaxy/
echo "Installing universe default nesi config your original config\
     was moved to universe_wsgi.ini.backup"
mv $GALAXY_HOME_FOLDER/universe_wsgi.ini $GALAXY_HOME_FOLDER/universe_wsgi.ini.backup
cp $OTAGO_GALAXY_LOCATION/nesi/universe_wsgi.ini $GALAXY_HOME_FOLDER/universe_wsgi.ini

echo "Nesi Installed reboot your galaxy instance to watch the magic work"
