#!/bin/bash

echo "Moving 

- genetics.py, 
- tool_conf.xml 
- datatypes_conf.xml 

into proper locations..."

cp -f ../datatypes/genetics.py ~/galaxy-dist/lib/galaxy/datatypes/
cp -f tool_conf.xml ~/galaxy-dist/
cp -f datatypes_conf.xml ~/galaxy-dist/

echo -e "\nDone!"
