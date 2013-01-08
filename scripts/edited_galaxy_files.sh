#!/bin/bash

echo "Moving 

- genetics.py, 
- tool_conf.xml 
- datatypes_conf.xml 

into proper locations..."

cp -f ../datatypes/genetics.py ../../../lib/galaxy/datatypes/
cp -f tool_conf.xml ../../../
cp -f datatypes_conf.xml ../../../

echo -e "\nDone!"
