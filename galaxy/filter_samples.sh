#!/bin/bash
#
# Author: Ed Hills
# Date 9/12/12
#
# Filter by sampleId. Will separate the Sample specific data from
# input VCF and put them into a new VCF
#
# $1..($#-1) = sample ids
# $($#) = input file

SAMPLE_LIST=""
NUM_SAMPLES=$#

for ((i=1; i<NUM_SAMPLES; i++))
do
    eval INPUT=\$${i}
    SAMPLE_LIST="${SAMPLE_LIST}, $INPUT"
done
# Do vcftools stripById $SAMPLE_LIST < $1
# OR something
