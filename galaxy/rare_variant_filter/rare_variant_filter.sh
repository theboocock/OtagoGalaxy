#!/bin/bash
#
# Performs EVS / 1000 genome rare variant filtering
# Should be reasonably flexible for adding information in the future
#
# @author James Boocock
#
# $1 input.vcf
# $2 EVS data or 1000 genomes data evs
# $3 column to find rare variants
#  

if [ "$2" == "EVS" ]; then
	while read line
	do
		
	done < $1
elif [ "$2" == "1000" ]; then
while read line
	do 
		
	done < $1
fi
