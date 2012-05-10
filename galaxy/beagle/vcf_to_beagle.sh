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

PREFIX="galaxy"

cat $1 | ~/galaxy-dist/tool-data/shared/jars/beagle/vcf2beagle.jar $2 $PREFIX

gunzip *.gz

mv -f *.markers $3
mv -f *.bgl $4
mv -f *.gprobs $5
mv -f *.like $6
mv -f *.int $7
