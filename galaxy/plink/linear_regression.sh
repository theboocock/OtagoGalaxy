#!/bin/bash
#
# Will execute plink command and then move outputted file to correct output location.
# 
# Inputs
# $@ = command to be run
# $# = output file
# 
# TODO get this and xml file to display nosex file if its selected

# run command
$@

# move to proper location
mv plink.assoc.logistic $#
