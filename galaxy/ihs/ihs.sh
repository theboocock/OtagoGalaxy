#!/bin/bash

#
# $1 hap file
# $2 legend file
# $3 ancestral allele annotation
# $4 output file IHS
# $5 galaxy root directory
# $6 ancestral allele file/chromosome
#
# @author James Boocock
#

LEGEND_OUTPUT=''


if [ $3 == "1kg" ]; then
    START=`cat $2 | head -1 | awk '{print $2}'`
    END=`cat $2| tail -1 | awk '{print $2}'`
    tabix -fh ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/ALL.chr${6}.phase1_release_v3.20101123.snps_indels_svs.genotypes.vcf.gz ${6}:${START}-${END} > temp.vcf 2> /dev/null
    python $5/tools/OtagoGalaxy/galaxy/ihs/set_ancestral_allele.py temp.vcf ${2}> 'temp.legend'
    LEGEND_OUTPUT='temp.legend'
elif [ $3 == "input_file" ]; then
   echo $2 $6 | awk '{print $1 $2 $3 $7 $8}' > temp.legend
   LEGEND_OUTPUT=temp.legend
else
    LEGEND_OUTPUT=$2
fi
$5/tool-data/shared/ihs/./ihs $LEGEND_OUTPUT $1
exit 0
