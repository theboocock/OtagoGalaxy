#!/bin/bash
#
# Bash script for the multi region extraction tool
#
# Author James Boocock
#
# $1 output file
# $2 dbsnp_annotation
# $3 input_vcf


# read regions.

i=0


gzip $input_vcf > "${input_vcf}.gz"
tabix -p vcf "${input_vcf}.gz"

#read regions in from stdin
while read line
do

#if this is the first region preseve the header
if [ "i" == 0 ] then;
	tabix -h ${line} "${input_vcf}.gz" >> ~input.tmp
else
	tabix ${line} "${input_vcf}.gz" >> ~input.tmp
fi

if [ "${dbsnp_annotation}" == "True" ]; then
	tabix -h galaxy-dist/tools/data/dbSNP.vcf.gz ${line} > ~dbsnp.tmp
	java -jar ~/galaxy-dist/tool-data/shared/jars/snpEff/SnpSift.jar annotate ~dbsnp.tmp ~input.tmp 1> ~tmp.tmp 2> /dev/null
	mv -f ~tmp.tmp ~input.tmp
	rm -f ~dbsnp.tmp
fi
cat ~input.tmp >> $1
rm -f ~input.tmp

i=`expr ${i}+1`
done

rm -f "${input_vcf}.gz"
rm -f "${input_vcf}.gz.tbi"


cat $1 | grep ^# >> ~tmp.tmp 
cat $1 | grep -v ^# | sort -k1,1d -k2,2n >> ~tmp.tmp
mv -f ~tmp.tmp $1

#if [ "$dbnsnp" == "True" ]; then
	#Small annotation seem to be the way to go.
#fi

