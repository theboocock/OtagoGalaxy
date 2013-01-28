#!/bin/bash

GALAXY_HOME_FOLDER=~/work/test_galaxy-central/galaxy-central
echo "Installing Clustering Interface"
cp grid_selection/mod_galaxy/handler.py $GALAXY_HOME_FOLDER/lib/galaxy/jobs/
cp -R grid_selection/clustering $GALAXY_HOME_FOLDER/lib/galaxy/jobs/ 



