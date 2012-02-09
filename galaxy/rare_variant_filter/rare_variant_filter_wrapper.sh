#!/bin/bash
#
# @author James Boocock
#
# Rare variant filter removes variants
# that are present above a certain percentage threshhold
#
#$1 input_vcf 
#$2 threshold
#$3 population
#

THRESHOLD=$2

if [ "$3" ~= /^1000/ ]; then
	if [ "$3" == "all_1000" ]; then
		AF 
	elif [ "$3" == "all_europe" ]; then
		EUR_AF
	elif [ "$3" == "all_easta" ]; then
		ASN_AF
	else
		AMR_AF
	fi
else
	if [ "$3" == "evs_all" ]; then
		
		TAC
	elif [ "$3" == "evs_euaw"]; then
		EU_AC
	else
		AA_AC
	fi
fi
