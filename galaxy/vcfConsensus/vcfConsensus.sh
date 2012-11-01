#!/bin/bash
# File: vcfConsensus.sh
# Author: Edward Hills
# Date: 2/11/12
# Description: Compresses the vcf file and runs tabix over it.
# Will then calcualte the consensus sequence given the 
# tabixed vcf and a fasta file
#
# INPUTS
# $1 input fasta
# $2 input vcf 
# $3 output file

bgzip -c $2 > tmp_vcf.gz

tabix tmp_vcf.gz

cat $1 | vcf-consensus tmp_vcf.gz > $3

exit 0 
