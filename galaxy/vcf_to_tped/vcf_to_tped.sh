#!/bin/bash
#
# Wrapper for vcftools
# Converts input vcf into tped and fped files
#
# Author: Edward Hills
# Date: 29/05/12
#
# Inputs
# $1 Input VCF
# $2 tped out filename
# $3 tfam out filename

vcftools --vcf $1 --plink-tped --out out

mv -f *.tped $2
mv -f *.tfam $3
