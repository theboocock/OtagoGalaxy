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
	Onekg_VCF="/media/Documents/galaxy/extra_database_files/1kg_october2012/ALL.chr${chr}.integrated_phase1_v3.20101123.snps_indels_svs.genotypes.vcf.gz"
    echo $Onekg_VCF

	if [ "${i}" == "0" ] ; then
		tabix -h ${Onekg_VCF} ${chr}:${reg} >> $2
	else
		tabix ${Onekg_VCF} ${chr}:${reg} >> $2
	fi


	i=`expr $i + 1`

done < $1
cat $2 | vcf-sort > out.tmp
mv out.tmp $2
