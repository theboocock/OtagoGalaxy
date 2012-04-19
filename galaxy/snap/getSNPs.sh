#!/bin/bash
#
# File: getSNPs.sh
# Author: Edward Hills
# Date: 27/04/12
# Description: Will print the list of snps in the column given
#
# Inputs
# $1 File containing SNPs
# $2 Column containing SNPs

cat $1 | awk -v column=$2 '{print $column}'

echo -e "\n\nNow you can go to:\n"
echo -e "http://www.broadinstitute.org/mpg/snap/ldsearch.php\n"
echo -e "Once you are there you can change the drop down box from 'File' to 'Text' and copy and paste the text above into it."  

