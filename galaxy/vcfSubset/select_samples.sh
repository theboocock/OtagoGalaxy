#!/bin/bash
#
# Author: Ed Hills
# Date 9/12/12
#
# Filter by sampleId. Will separate the Sample specific data from
# input VCF and put them into a new VCF
#
# $1 = sample ids
# $2 = input file
# $3 = output file
#

SAMPLE_LIST=`cat $1`
INPUT_FILENAME=$2
OUTPUT_FILENAME=$3
bgzip -c $INPUT_FILENAME > INPUT.gz
tabix -p vcf INPUT.gz

vcf-subset -c $SAMPLE_LIST INPUT.gz > $OUTPUT_FILENAME

exit 0
