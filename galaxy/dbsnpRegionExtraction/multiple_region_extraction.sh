#!/bin/bash
#
# Bash script for the multi region extraction tool
#
# Author James Boocock
#
# $1 output file
# $2 dbsnp_annotation
# $3 input_vcf
# $4 regions text file

# read regions.

i=0


bgzip -c $3 > "${3}.gz"
tabix -p vcf "${3}.gz"
#read regions in from stdin
while read line
do
echo $i
#if this is the first region preseve the header
if [ "${i}" == "0" ] ; then
	tabix -h "${3}.gz" ${line} >> ~input.tmp
else
	tabix  "${3}.gz" ${line} >> ~input.tmp
fi

#if dbsnp annotation was asked for. Annotate each region on the fly
if [ "${2}" == "True" ] ; then
	tabix -h galaxy-dist/tools/data/dbSNP.vcf.gz ${line} > ~dbsnp.tmp
	java -jar ~/galaxy-dist/tool-data/shared/jars/snpEff/SnpSift.jar annotate ~dbsnp.tmp ~input.tmp 1> ~tmp.tmp 2> /dev/null
	mv -f ~tmp.tmp ~input.tmp
	rm -f ~dbsnp.tmp
fi
cat ~input.tmp >> $1
rm -f ~input.tmp

# increment i
i=`expr $i + 1`
done <$4


# Remove Temporary files.
rm -f "${3}.gz"
rm -f "${3}.gz.tbi"


# Sort the vcf file incase the txt file was not in sorted order
cat $1 | grep ^# >> ~tmp.tmp 
cat $1 | grep -v ^# | sort -k1,1d -k2,2n >> ~tmp.tmp
mv -f ~tmp.tmp $1


