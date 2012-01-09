#!/bin/bash
# Get the sample ids out of a given vcf file
# author: James Boocock
# date: 09/01/2011
#
# $1 Input File to extract the ids from.

OUTPUT=`grep "^#[^#]" -m 1 $1`
for line in $OUTPUT
do
        if [ $line != "#CHROM" -a $line != "FORMAT" -a $line != "POS" -a $line != "ID" -a $line != "REF" -a $line != "ALT" -a $line != "QUAL" -a $line != "FILTER" -a $line != "INFO" ]
then
    echo $line
fi
done
