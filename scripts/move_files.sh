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

MYLOC=`pwd`

# Copy handy scripts to root directory

sudo cp -f restart_galaxy.sh /home/galaxy/galaxy-dist/
sudo cp -f start_galaxy.sh /home/galaxy/galaxy-dist/
sudo cp -f stop_galaxy.sh /home/galaxy/galaxy-dist/
sudo cp -f start_webapp.sh /home/galaxy/galaxy-dist/

# Copy config files to root directory
sudo cp -f universe_wsgi.ini /home/galaxy/galaxy-dist/
sudo cp -f universe_wsgi.runner.ini /home/galaxy/galaxy-dist/
sudo cp -f universe_wsgi.webapp.ini /home/galaxy/galaxy-dist/

# Setup tool_conf.xml
sudo cp -f tool_conf.xml /home/galaxy/galaxy-dist/

#Setup VCF to CSV 
sudo mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/vcf_to_csv
sudo cp -f ../src/vcf_to_csv/VcfToCsv.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/vcf_to_csv

# Setup snpEff
sudo mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
sudo cp -f ../src/snpEff/SnpSift.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
sudo cp -f ../src/snpEff/snpEff.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
sudo cp -f ../src/snpEff/snpEff.config /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
sudo mkdir /home/galaxy/galaxy-dist/tools/snpEff
sudo cp -f ../src/snpEff/galaxy/snpEff.xml /home/galaxy/galaxy-dist/tools/snpEff/
cd /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff
mkdir -f data
java -jar snpEff.jar download GRCh37.63
java -jar snpEff.jar download GRCh37.64
java -jar snpEff.jar download GRCh37.65
java -jar snpEff.jar download hg19
cd $MYLOC

# Setup VcfTools
sudo cp -f ../src/vcfperltools /home/galaxy/galaxy-dist/tool-data/shared/

# Setup GATK
sudo mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/gatk
sudo cp -f ../src/gatk/GenomeAnalysisTK.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/gatk/
sudo cp -Rf ../src/gatk /home/galaxy/galaxy-dist/tools/

# Setup EVS
sudo cp -fR ../src/evs/ /home/galaxy/galaxy-dist/tool-data/shared/jars/

# Move AlleleFreq jar files to directory
sudo mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/alleleFreq
sudo cp -f ../src/getAlleleFreqSummary/GetAlleleFreqSummary.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/alleleFreq/

# Download Visualisation things
sudo mkdir /home/galaxy/galaxy-dist/tool-data/shared/ucsc/chrom
echo Downloading Reference Genomes for Visualisations.. this may take some time..
python /home/galaxy/galaxy-dist/cron/build_chrom_db.py /home/galaxy/galaxy-dist/tool-data/shared/ucsc/chrom/

# Move haploview
sudo mkdir /home/galaxy/galaxy-dist/tool-data/shared/jars/haploview
sudo cp -f ../src/haplo/Haploview.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/haploview/

# Download 1kg allele frequency data
echo Downloading 1000genomes files... ~1.3gb..
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/ALL.wgs.phase1_integrated_calls.20101123.snps_indels_svs.sites.vcf.gz
mkdir /home/galaxy/galaxy-dist/tools/SOER1000genes/data/1kg
mkdir /home/galaxy/galaxy-dist/tools/SOER1000genes/data/1kg/vcf
tabix -p vcf ALL.wgs.phase1_integrated_calls.20101123.snps_indels_svs.sites.vcf.gz
cp -f ALL.wgs.phase1.integrated_calls.* /home/galaxy/galaxy-dist/tools/SOER1000genes/data/1kg/vcf/

# Shift all the tools
sudo cp -fR ../galaxy/ /home/galaxy/galaxy-dist/tools/SOER1000genes/

# Install dbSNP
echo "Downloading dbSNP135 (~9Gb).. This may take some time.."
echo "If you already have dbSNP and its tabix file please put them in /home/galaxy/galaxy-dist/tools/SOER1000genes/data/ folder named 00-All.vcf.gz and 00-All.vcf.gz.tbi accordingly and exit the script."
sudo wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/v4.0/00-All.vcf.gz 
sudo mkdir /home/galaxy/galaxy-dist/tools/SOER1000genes/data
sudo mv -f 00-All.vcf.gz /home/galaxy/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz
sudo tabix -p vcf /home/galaxy/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz

echo Done!
