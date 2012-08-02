#!/bin/bash

# $1 = my vcf
# $2 = <= || >=
# $3 = value for grep in myvcf
# $4 = <= || >=
# $5 = value for grep in 1kg
# $6 = SNPs or Indels (not yet implemented)
#TODO ^^

ONEKG_VCF=`ls ~/galaxy-dist/tools/SOER1000genes/data/1kg/vcf/ALL.*.gz`

while read line
    do
        HEADER=`echo $line | awk '{if ($1 ~ /^#/) {print $0}}'`
        if [ "$HEADER" == "" ]
        then
            break
        fi

        echo $HEADER >> header.txt

    done < $1

# Filter original
while read line
    do
        echo $line | grep "AF=${3}" >> filtered_myVCF.vcf
    done < $1


# get positions from filtered original
awk '{print $1":"$2"-"$2}' < filtered_myVCF.vcf >| pos1.txt

# gets position from my filtered vcf
while read line
    do
        tabix -f $ONEKG_VCF "$line" >> filtered.1kg.vcf
    done < pos1.txt


#filter 1kg vcf
cat filtered.1kg.vcf | grep "AF=${5}" > final_filtered_1kg.vcf
 

awk '{print $1":"$2"-"$2}' < final_filtered_1kg.vcf >| pos2.txt

bgzip -c > filtered_myVCF.vcf
tabix -p vcf filtered_myVCF.vcf.gz

while read line
    do
        tabix -f filtered_myVCF.vcf "$line" >> header.txt
    done < pos2.txt

mv header.txt final_filtered.vcf

exit 0
