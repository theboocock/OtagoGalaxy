#!/bin/bash
# 
# Splits input from galaxy textboxes and passes it on to actual work
#
# Author: Ed Hills
# Date: 01/05/2012
#
# Inputs
# $1 = vcf file
# $2 = my_af
# $3 = end_af
# $4 = what_to_filter

INPUTS=`echo $4 | tr "," " "`

/home/galaxy/galaxy-dist/tools/SOER1000genes/galaxy/compare1kg/./compare1kg.sh $1 $2 $3 $INPUTS

