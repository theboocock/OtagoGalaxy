# Author: Edward Hills & James Boocock
# Date: 30/11/11
#
# A wrapper that wraps all the functions that need to be called by 
# dbsnp_region_extraction.xml for Galaxy.
#
# Params:
# $1 = input1
# $2 = variants_annotated
# $3 = region

REGIONS=""
if [ $# == 3 ]
then

    REGIONS=$3
    python ~/galaxy-dist/tools/vcf_tools/vcfPytools.py extract --in=${1} --out=~tmpReg.tmp --region=${REGIONS}

else

    REGIONS=`/home/galaxy/galaxy-dist/tools/SOER1000genes/galaxy/dbsnpRegionExtraction/getRegion.sh $1`
    echo $REGIONS    
    python ~/galaxy-dist/tools/vcf_tools/vcfPytools.py extract --in=${1} --out=~tmpReg.tmp --region=${REGIONS}

fi

tabix -h ~/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz ${REGIONS} > ~tmp.tmp

java -jar ~/galaxy-dist/tool-data/shared/jars/snpEff/SnpSift.jar annotate ~tmp.tmp ~tmpReg.tmp 1> $2 2> /dev/null

rm -f ~tmp.tmp
rm -f ~tmpReg.tmp
