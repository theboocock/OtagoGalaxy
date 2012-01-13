#!/bin/bash
#
# @Author: Ed Hills
# @Date: 13/01/012
#
# Will move the contents of this folder into the root
# galaxy installation folder.
#

# Start script
echo Starting install...

# Copy handy scripts to root directory
mv -f restart_galaxy.sh /home/galaxy/galaxy-dist/
mv -f start_galaxy.sh /home/galaxy/galaxy-dist/
mv -f stop_galaxy.sh /home/galaxy/galaxy-dist/

# Copy config files to root directory
mv -f universe_wsgi.ini /home/galaxy/galaxy-dist/
mv -f universe_wsgi.runner.ini /home/galaxy/galaxy-dist/
mv -f universe_wsgi.webapp.ini /home/galaxy/galaxy-dist/

# Setup tool_conf.xml
mv -f tool_conf.xml /home/galaxy/galaxy-dist/

# Setup snpEff
mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
mv -f ../src/snpEff/SnpSift.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
mv -f ../src/snpEff/snpEff.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
mv -f ../src/snpEff/snpEff.config /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
mv -fr ../src/snpEff/data /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
mkdir /home/galaxy/galaxy-dist/tools/snpEff
mv -f ../src/snpEff/snpEff.xml /home/galaxy/galaxy-dist/tools/snpEff/

# Setup VcfTools
mv -f ../src/vcfperltools /home/galaxy/galaxy-dist/tool-data/shared/

# Setup GATK
mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/gatk
mv -f ../src/gatk/GenomeAnalysisTK.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/
mv -f ../src/gatk /home/galaxy/galaxy-dist/tools/

# Install dbSNP
echo "Downloading dbSNP135 (~9Gb).. This may take some time.."
wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/v4.0/00-All.vcf.gz 
mkdir ../data
mv -f 00-All.vcf.gz ../data/
tabix -p vcf ../data/00-All.vcf.gz

# Finish and delete cruft
rm -fr ../src
rm -fr .

echo Done
