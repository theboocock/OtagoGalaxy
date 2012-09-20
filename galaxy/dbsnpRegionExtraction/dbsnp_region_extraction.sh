#!/bin/bash
# Author: Edward Hills & James Boocock
# Date: 30/11/11 - Updated: 8/2/12
#
# Finds the region (either specified or calculted), tabix's the dbsnp
# region with the region found, and then has its rsids annotated onto
# the input file given.
#
# Params:
# $1 = input1
# $2 = variants_annotated
# $3 = region

if [ $# -eq 3 ]
then
    REGIONS=${3/-/..}
    python ~/galaxy-dist/tools/vcf_tools/vcfPytools.py extract --in=${1} --out=~tmpReg.tmp --region=${REGIONS}

    tabix -h ~/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz ${REGIONS} > ~tmp.tmp
    java -jar ~/galaxy-dist/tool-data/shared/jars/snpEff/SnpSift.jar annotate ~tmp.tmp ~tmpReg.tmp 1> $2 

else

    /home/galaxy/galaxy-dist/tools/SOER1000genes/galaxy/dbsnpRegionExtraction/./getRegion.sh $1

    while read line
    do
        python ~/galaxy-dist/tools/vcf_tools/vcfPytools.py extract --in=${1} --region=${line/-/..} >> ~tmpReg.tmp
        tabix -h ~/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz ${line} > ~tmp.tmp
        java -jar ~/galaxy-dist/tool-data/shared/jars/snpEff/SnpSift.jar annotate ~tmp.tmp ~tmpReg.tmp 1>> $2 
   
    done < ~reg.tmp

fi

# cleanup
rm -f ~tmp.tmp
rm -f ~tmpReg.tmp
rm -f ~reg.tmp

exit 0
