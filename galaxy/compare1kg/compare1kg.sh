#!/bin/bash

# FIXME: All references of 1kg are no longer true as we now use evs too.
# $1 = my vcf
# $2 = <= || >=
# $3 = af value 1
# $4 = <= || >=
# $5 = af value 2 (for 1kg)
# $6 = search SNPs or Indels or both
# $7 = output vcf
# $8 = database
# $9 = population - if database == evs

if [ "$8" == "1kg" ] 
then
    DATABASE=`ls ~/galaxy-dist/tools/SOER1000genes/data/1kg/vcf/ALL.*.gz`
else
    DATABASE=`ls ~/galaxy-dist/tools/SOER1000genes/data/evs/esp/ESP6500.ALL.snps.vcf.gz`
fi

# Print out header into new file
cat $1 | awk '{if ($1 ~ /^#/) {print $0}}' > $7

# Filter original

~/galaxy-dist/tools/SOER1000genes/galaxy/compare1kg/./alleleFreqFilter.sh $1 $3 $2 $6 $8 $9 >| filtered_myVCF.vcf

# get positions from filtered original
awk '{print $1":"$2"-"$2}' < filtered_myVCF.vcf >| pos1.txt

bgzip filtered_myVCF.vcf
tabix -fp vcf filtered_myVCF.vcf.gz

if [ ! -f pos1.txt ]; then
    echo "No snps returned on first operation" >& 2
    exit 1
fi
# gets position from my filtered vcf
while read line
    do
        tabix -f $DATABASE $line >> filtered.1kg.vcf
    done < pos1.txt
#filter 1kg vcf
~/galaxy-dist/tools/SOER1000genes/galaxy/compare1kg/./alleleFreqFilter.sh `pwd`/filtered.1kg.vcf $5 $4 $6 $8 $9 >| final_filtered_1kg.vcf
awk '{print $1":"$2"-"$2}' < final_filtered_1kg.vcf >| pos2.txt
# print out all those that match the 1kg and myvcf
while read line
    do
       tabix -f filtered_myVCF.vcf.gz $line >> $7
       
    done < pos2.txt

exit 0

