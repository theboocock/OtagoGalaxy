#!/bin/bash
# @Date 9/01/2012
# @Author Ed Hills
#
# This file will take a white space separated list of file names,
# and run the vcf-merge tool and merge all files into a new file.
# 
# INPUTS
# $1 = First input File
# $2 = Second input File
# $N = Extra input files

FILE_LIST=""

cat $1 | bgzip -c > ~tmp1.vcf.gz
cat $2 | bgzip -c > ~tmp2.vcf.gz

tabix -p vcf ~tmp1.vcf.gz
tabix -p vcf ~tmp2.vcf.gz

FILE_LIST="~tmp1.vcf.gz ~tmp2.vcf.gz"

if [ $# > 2 ]
then
    for ((i=3; i <= $#; i++))
    do
        eval EXTRA_FILE=\$${i}
        cat $EXTRA_FILE | bgzip -c > ~tmp${i}.vcf.gz
        tabix -p vcf ~tmp${i}.vcf.gz
        FILE_LIST="${FILE_LIST} ~tmp${i}.vcf.gz"
    done
fi

perl ~/galaxy-dist/tool-data/shared/vcfperltools/vcf-merge ${FILE_LIST}

rm -f ~tmp*

