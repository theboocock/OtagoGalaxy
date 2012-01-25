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

mv $1 "${1}.fasta"
mv $2 "${2}.vcf"
mv $3 "${3}.vcf"

if ["$5" -eq "1" ] ; then
 java -jar ~/galaxy-dist/tool-data/shared/jars/gatk/GenomeAnalysisTK.jar -T VariantAnnotator -R "${1}.fasta" -A -SnpEff --variant "${2}.vcf"  --snpEffFile "${3}.vcf"  -L "${2}.vcf"  -o $4.vcf 

else
 java -jar ~/galaxy-dist/tool-data/shared/jars/gatk/GenomeAnalysisTK.jar -T VariantAnnotator -R "${1}.fasta" -E resource.EFF --variant "${2}.vcf" --snpEffFile "${3}.vcf"  -L "${2}.vcf"  -o "${4}.vcf" 

fi
mv "${1}.fasta" $1
mv "${2}.vcf" $2
mv "${3}.vcf" $3
mv "${4}.vcf" $4


