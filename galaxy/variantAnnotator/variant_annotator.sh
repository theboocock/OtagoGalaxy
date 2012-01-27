#!/bin/bash
#
# SnpEff Variant Annotation using GATK 
#
#@date 24/01/2011
#@author James Boocock
#
#
# $1 reference FastaFile
# $2 Input VCF 
# $3 SnpEff Vcf Output File
# $4 OUTPUT VCF
# $5 Option either 1 or 2
#

cp $1 "${1}.fasta"
cp $2 "${2}.vcf"
cp $3 "${3}.vcf"

if [ "$5" == "1" ] ; then
java -jar -Xmx6G ~/galaxy-dist/tool-data/shared/jars/gatk/GenomeAnalysisTK.jar -T VariantAnnotator -R "${1}.fasta" -A SnpEff --variant "${2}.vcf"  --snpEffFile "${3}.vcf"  -L "${2}.vcf"  -o $4.vcf 

else
java -jar ~/galaxy-dist/tool-data/shared/jars/gatk/GenomeAnalysisTK.jar -T VariantAnnotator -R "${1}.fasta" -E resource.EFF --variant "${2}.vcf" --resource "${3}.vcf"  -L "${2}.vcf"  -o "${4}.vcf" 

fi
cp -f "${1}.fasta" $1
cp -f "${2}.vcf" $2
cp -f "${3}.vcf" $3
cp -f "${4}.vcf" $4

rm -f "${1}.fasta"
rm -f "${2}.vcf"
rm -f "${3}.vcf"
rm -f "${4}.vcf"

