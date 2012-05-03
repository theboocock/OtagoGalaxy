#!/bin/bash
#

FILTER_BY=""


while read line
do
    FINAL_POS=""
    CHROM=`echo $line | awk '{if ($1 !~ /^#/) {print $1}}'`
    if [ "$CHROM" != ""  ]
    then
        POS=`echo $line | awk '{print $2}'`
        FINAL_POS="$CHROM:$POS-$POS"

        tabix -f ../../data/1kg/vcf/ALL.wgs.phase1_release_v2.20101123.snps_indels_sv.sites.vcf.gz $FINAL_POS >> 1kg.tmp
    fi
done < filtered_original.tmp


# bgzip filtered_original.tmp
bgzip filtered_original.tmp

# tabix orig file
tabix -p vcf filtered_original.tmp.gz

while read line
do
    FINAL_POS=""
    CHROM=`echo $line | awk '{if ($1 !~ /^#/) {print $1}}'`
    if [ "$CHROM" != ""  ] 
    then
        POS=`echo $line | awk '{print $2}'`
        FINAL_POS="$CHROM:$POS-$POS"

        tabix -f filtered_original.tmp.gz $FINAL_POS >> original_end.tmp
    fi
done < 1kg_filtered.tmp

