#!/bin/bash

GALAXY_HOME_FOLDER=~/galaxy-dist
echo "Installing Clustering Interface"
cp grid_selection/mod_galaxy/handler.py $GALAXY_HOME_FOLDER/lib/galaxy/jobs/
cp grid_selection/mod_galaxy/config.py $GALAXY_HOME_FOLDER/lib/galaxy/
cp -R grid_selection/clustering $GALAXY_HOME_FOLDER/lib/galaxy/jobs/ 



