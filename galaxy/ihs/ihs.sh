#!/bin/bash

#
# $1 hap file
# $2 legend file
# $3 ancestral allele annotation
# $4 chromosome
# $5 output file IHS
# $6 galaxy root directory
# $7 ancestral allele file
#
# @author James Boocock
#

LEGEND_OUTPUT=''


if [ $3 == "1kg" ]; then
    START=`cat $2 | head -1 | awk '{print $2}'`
    END=`cat $2| tail -1 | awk '{print $2}'`
    echo $START
    echo $END
    tabix -fh ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/ALL.chr${4}.phase1_release_v3.20101123.snps_indels_svs.genotypes.vcf.gz ${4}:${START}-${END} > temp.vcf 2> /dev/null
    python $6/tools/SOER1000genes/galaxy/ihs/set_ancestral_allele.py temp.vcf ${2} 
    LEGEND_OUTPUT='temp.legend'
elif [ $3 == "input_file" ]; then
   echo $2 $5 | awk '{print $1 $2 $3 $7 $8}' > temp.legend
   LEGEND_OUTPUT=temp.legend
else
    LEGEND_OUTPUT=$2
fi
$6/tools/SOER1000genes/galaxy/ihs/iHS/./ihs $LEGEND_OUTPUT $1 > $5
exit 0
