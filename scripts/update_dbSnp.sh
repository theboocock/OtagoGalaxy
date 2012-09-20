#!/bin/bash
#
# @Author: Ed Hills
# @Date: 20/01/12
#
# This will get the latest dbSnp and place it where it needs to be.
#

echo "Beginning update... this may take some time.. (and bandwidth)"

# Download dbSnp
wget -N ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/v4.0/00-All.vcf.gz
mv -f 00-All.vcf.gz /home/galaxy/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz
tabix -p vcf /home/galaxy/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz

echo "Done!"
