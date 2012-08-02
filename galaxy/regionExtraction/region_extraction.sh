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

cp -f $1 ~input.tmp
bgzip -c ~input.tmp > ~input.tmp.gz
tabix -p vcf ~input.tmp.gz
tabix -h ~input.tmp.gz $3 > $2
rm ~input.tmp*

exit 0
