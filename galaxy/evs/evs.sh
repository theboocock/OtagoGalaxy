#!/bin/bash
#
# @Author: Ed Hills
# @Date: 23/01/12
#
# This script will run the evsClient.jar and make sure that galaxy
# can find its 3 separate outputs
#
# Inputs
# $1 = input_data
# $2 = file_format
# $3 = output_vcf
# $4 = output_allSites
# $5 = output_summaryStats

# run program
java -jar /home/galaxy/galaxy-dist/tool-data/shared/jars/evs/evsClient.jar -t $1 -f $2 > /dev/null

# move files around
mv -f *.vcf $3
mv -f *AllSites.txt $4
mv -f *SummaryStats.txt $5
