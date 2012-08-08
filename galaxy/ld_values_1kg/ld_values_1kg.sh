#!/bin/bash
#
# Wrapper for 1000 genomes LD values script
#
# author: James Boocock
# date : 7/08/2012
#
#


usage(){
cat << EOF
	 Usage: This bash script obtains LD calculation from 1000 genomes VCFs
	 	or a users uploaded VCF file.
	
	-o  <VCF_FILE> user vcf file
	-r  <RSID>     single snp to calculate LD for
	-s  <SNP_LIST> text file containing snp rsid to calculate ld of.
	-c  <REGION>   Chromosome region and position to calculate ld for.
	-w  <WINDOW>   LD distance in number of snps
	-r  <R2>       only show snps above this ld frequency
	-l  <KB>       Max distance away from snp to calculate LD
	-m  	       Output data in a matrix
EOF


}

getoptions(){
while getopts "o:r:s:c:w:r:l:m" opt;  do
case $opt in
o)
	VCF_INPUT=$OPTARG
;;
r)
	RSID=$OPTARG
;;
s)
	SNP_LIST=$OPTARG
;;
c)
	REGION=$OPTARG
;;
w)
	WINDOW=$OPTARG
;;
r)
	R2=$OPTARG
;;
l)
	KB=$OPTARG
;;
m)
	MATRIX="TRUE"
;;
i)      ID_LIST=$OPTARG
o)
	PLINK_OUTPUT=$OPTARG
;;
?)
usage
exit 1
;;
esac
done

}

getoptions
if [ "$VCF_INPUT" != "" ]; then
	gzip $VCF_INPUT	
	tabix $VCF_INPUT.gz
	tabix -fh $VCF_INPUT.gz $REGION > temp.vcf
else
	tabix -fh ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/ALL.`awk -F [\:] '{print $1}'`.phase1_release_v3.20101123.snps_indels_svs.genotypes.vcf.gz $REGION > temp.vcf
fi

	#subset vcf file
	vcfsubset -c $ID_LIST temp.vcf 
	#convert to plink format
	vcftools --plink-tped --out plinkfile 
	PLINK_COMMAND=p-link --tped plinkfile.tped --tfam plinkfile.tfam --r2 --noweb --ld-window $WINDOW \
		      --ld-window-r2 $R2 --ld-window-kb $KB
	if [ "$SNP_LIST" != "" ]; then
		PLINK_COMMAND=${PLINK_COMMAND} --ld-snp-list $SNP_LIST
	fi
	if [ "$MATRIX" == "TRUE" ]; then
		PLINK_COMMAND=${PLINK_COMMAND}  --matrix
	fi
	eval $PLINK_COMMAND


	

