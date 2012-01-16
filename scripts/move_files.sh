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
mv -f start_webapp.sh /home/galaxy/galaxy-dist/

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
mv -f ../src/snpEff/data /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
mkdir /home/galaxy/galaxy-dist/tools/snpEff
mv -f ../src/snpEff/snpEff.xml /home/galaxy/galaxy-dist/tools/snpEff/

# Setup VcfTools
mv -f ../src/vcfperltools /home/galaxy/galaxy-dist/tool-data/shared/

# Setup GATK
mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/gatk
mv -f ../src/gatk/GenomeAnalysisTK.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/
mv -f ../src/gatk /home/galaxy/galaxy-dist/tools/

# Shift all the tools
cp -fR ../galaxy/ /home/galaxy/galaxy-dist/tools/SOER1000genes/

# Install dbSNP
echo "Downloading dbSNP135 (~9Gb).. This may take some time.."
echo "If you already have dbSNP and its tabix file please put them in /home/galaxy/galaxy-dist/tools/SOER1000genes/data/ folder named 00-All.vcf.gz and 00-All.vcf.gz.tbi accordingly and exit the script."
wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/v4.0/00-All.vcf.gz 
mkdir /home/galaxy/galaxy-dist/tools/SOER1000genes/data
mv -f 00-All.vcf.gz /home/galaxy/galaxy-dist/tools/SOER1000genes/data/
tabix -p vcf /home/galaxy/galaxy-dist/tools/SOER1000genes/data/00-All.vcf.gz

echo Done!
