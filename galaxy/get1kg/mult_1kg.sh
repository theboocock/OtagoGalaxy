#!/bin/bash
#
# Bash script for multiple region extraction from 1000genomes
#
# Author James Boocock
#
# $1 region_txt
# $2 output_vcf
#
i=0
while read line
do
	chr=`echo ${line} | awk -F [':'] '{print $1}'`
	reg=`echo ${line} | awk -F [':'] '{print $2}'`
	1kg_VCF=/media/Documents/galaxy/extra_database_files/ALL.chr${chr}.phase1_release_v3.20101123.snps_indels_svs.genotypes.vcf.gz
	if [ "${i}" == "0" ] ; then
		tabix -h ${1kg_VCF} ${chr}:${reg} >> $2
	else
		tabix ${1kg_VCF} ${chr}:${reg} >> $2
	fi


	i=`expr $i + 1`

done < $1
