#!/bin/bash
# File: processSNPs.sh
# Date: 18/11/11
# Authors: Edward Hills and James Boocock
# Description: Bash script to match the SNP search list with the data
#              list, process major and minor allele frequencies,
#              deletes SNPs with deletes and appends a allele value
#              to each SNP.
#
# Parameter input to bash script:
# $1 - SNP Search List
# $2 - Data File
# $3 - output file name
# $4 - Block size
# $5 - To delete or not

if [ ! $# == 4 ]; then
    echo "Usage is: ./processSNPs.sh <snp_search_file> <data_file> <output_file> <block_size> <dels/no-dels>"
    exit
else
    ./snpsearch -t $4 -n `wc -l $1` -i $1 -o $3 < $2
    java ProcessAlleles $3 $4 $5
    rm -f $3
    mv ~tmp.tmp $3
fi
