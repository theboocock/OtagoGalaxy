#!/bin/bash
#
# Author: Ed Hills
# Date: 10/12/11
#
# The idea of this script is to take a file containing all input datasets,
# ie. a file with 600 patients and different and a range of different
# SNPs, and randomly grab a specified number of those SNPs which can then
# be run by the processSNPs.sh script.
#
# Parameters:
# $1 = input file
# $2 = Number of lines to return
# $3 = Final Output Name

if [ $# != 3 ] 
then
    echo "Usage: ./generateRandomSnps.sh <input_file> <number_of_lines_to_return> <final_output_name>"
exit
fi

echo "Processing ${2} random SNPS into ${3}"

cat $1 | awk '{print $2}' | uniq > ~allSnps.tmp

INPUT_NUM_LINES=`wc -l ~allSnps.tmp | awk '{print $1}'`

java RandomiseBlock $INPUT_NUM_LINES $2 

cat ~tmp.tmp | sort > ~sortedNums.tmp

java PrintLines ~sortedNums.tmp ~allSnps.tmp $INPUT_NUM_LINES > $3

rm -f ~tmp.tmp
rm -f ~sortedNums.tmp
rm -f ~allSnps.tmp

echo "Successfully outputted ${2} random SNPS into ${3}"

