#!/bin/bash
#
# This is a wrapper for vcf2beagle.jar
#
# Inputs: 
# $1 = input_vcf
# $2 = missing delimitter
# $3 = output_marker
# $4 = output_bgl
# $5 = output_gprobs
# $6 = output_like
# $7 = output_int

PREFIX=`date '+%s'`

PWD=`pwd`

cat $1 | java -jar ~/galaxy-dist/tool-data/shared/jars/beagle/vcf2beagle.jar $2 $PREFIX

echo "$2"

gunzip $PWD/$PREFIX.*.gz

mv -f $PWD/$PREFIX.markers $3
mv -f $PWD/$PREFIX.bgl $4
mv -f $PWD/$PREFIX.gprobs $5
mv -f $PWD/$PREFIX.like $6
mv -f $PWD/$PREFIX.int $7
