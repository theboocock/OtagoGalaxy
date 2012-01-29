#!/bin/bash
#
# Author: Ed Hills
# Date: 26/01/12
#
# This tool will download the allele frequencies per population from 
# 1000genomes data based on gene region or gene name.
# It works by querying the 1000genomes data, finding the chromsone and
# region and will return the allele frequencies.
#
# Inputs
# $1 - region
# $2 - output_whole_vcf
# $3 - output_summary_txt 

CHROM=`echo ${1} | awk -F[:] '{print $1}'`
REGION=`echo ${1} | awk -F[:] '{print $2}'`

tabix -fh /home/galaxy/galaxy-dist/tools/SOER1000genes/data/1kg/vcf/ALL.wgs.phase1_intergrated_calls.20101123.snps_indels_svs.sites.vcf.gz ${CHROM}:${REGION} > $2

java -jar /home/galaxy/galaxy-dist/tool-data/shared/jars/alleleFreq/GetAlleleFreqSummary.jar $2 > $3

