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
# $6 - Random Selection or not
# $7 - Fill missing patients or not
# $8 - Patient list <- optional

if [ ! $# == 7 ]; then
    echo "Usage is: ./processSNPs.sh <snp_search_file> <data_file> <output_file> <block_size> <dels/no-dels> <random_selection_or_not> <fill_patients_or_not> <patient_list> <- optional"
    exit
else
    ./snpsearch -i $1 -o $3 < $2

    if [ "$7" == "fill" ]
    then
        java FillPatients $3 $8
    fi

    java ProcessAlleles $3 $5 $6 $4
    mv -f ~tmp.tmp $3
fi
