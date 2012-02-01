#!/bin/bash
#
# Bash Script performs region extraction operation on a
# VCF file.
# 
# Author James Boocock
#
# $1 input vcf file
# $2 output vcf file
# $3 region chromosome
#
#

cp $1 ~input.tmp
tabix -p vcf ~input.tmp
tabix -h ~input.tmp $2 > $3
rm ~input.tmp
