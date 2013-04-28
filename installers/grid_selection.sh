#!/bin/bash

GALAXY_HOME_FOLDER=~/work/galaxy-central
echo "Installing Clustering Interface"
echo "Also backing up files with .backup extension"

mv $GALAXY_HOME_FOLDER/lib/galaxy/jobs/handler.py $GALAXY_HOME_FOLDER/lib/galaxy/jobs/handler.py.backup
cp grid_selection/mod_galaxy/handler.py $GALAXY_HOME_FOLDER/lib/galaxy/jobs/
mv $GALAXY_HOME_FOLDER/lib/galaxy/config.py $GALAXY_HOME_FOLDER/lib/galaxy/jobs/config.py.backup
cp grid_selection/mod_galaxy/config.py $GALAXY_HOME_FOLDER/lib/galaxy/
mv $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/tasks.py $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners/tasks.py.backup
cp grid_selection/mod_galaxy/tasks.py $GALAXY_HOME_FOLDER/lib/galaxy/jobs/runners
#mv $GALAXY_HOME_FOLDER/lib/galaxy/tools/__init__.py $GALAXY_HOME_FOLDER/lib/galaxy/tools/__init__.py.backup
#cp grid_selection/mod_galaxy/__init__.py $GALAXY_HOME_FOLDER/lib/galaxy/tools/__init__.py


cp -R grid_selection/clustering $GALAXY_HOME_FOLDER/lib/galaxy/jobs/
#mv $GALAXY_HOME_FOLDER/templates/tool_form.mako $GALAXY_HOME_FOLDER/templates/tool_form.mako.backup
#cp grid_selection/ui/tool_form.mako $GALAXY_HOME_FOLDER/templates
cp grid_selection/conf/grid_conf.xml $GALAXY_HOME_FOLDER/


