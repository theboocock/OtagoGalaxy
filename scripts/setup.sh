#!/bin/bash
#
# @Author: Ed Hills
# @Date: 13/01/012
#
# Will move the contents of this folder into the root
# galaxy installation folder.
#

echo Shifting files...

cp -f restart_galaxy.sh /home/galaxy/galaxy-dist/
cp -f start_galaxy.sh /home/galaxy/galaxy-dist/
cp -f stop_galaxy.sh /home/galaxy/galaxy-dist/

cp -f universe_wsgi.ini /home/galaxy/galaxy-dist/
cp -f universe_wsgi.runner.ini /home/galaxy/galaxy-dist/
cp -f universe_wsgi.webapp.ini /home/galaxy/galaxy-dist/

cp -f tool_conf.xml /home/galaxy/galaxy-dist/

echo Done
