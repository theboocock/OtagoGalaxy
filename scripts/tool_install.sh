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

. tool_install.cfg

#Setup VCF to CSV 
sudo mkdir $GALAXY_INSTALLATION/tool-data/shared/jars/vcf_to_csv
sudo cp -f ../src/vcf_to_csv/VcfToCsv.jar $GALAXY_INSTALLATION/tool-data/shared/jars/vcf_to_csv

# Setup snpEff
sudo mkdir $GALAXY_INSTALLATION/tool-data/shared/jars/snpEff
sudo cp -f ../src/snpEff/SnpSift.jar $GALAXY_INSTALLATION/tool-data/shared/jars/snpEff
sudo cp -f ../src/snpEff/snpEff.jar $GALAXY_INSTALLATION/tool-data/shared/jars/snpEff
sudo cp -f ../src/snpEff/snpEff.config $GALAXY_INSTALLATION/tool-data/shared/jars/snpEff
sudo mkdir $GALAXY_INSTALLATION/tools/snpEff
sudo cp -f ../src/snpEff/galaxy/snpEff.xml $GALAXY_INSTALLATION/tools/snpEff/
cd $GALAXY_INSTALLATION/tool-data/shared/jars/snpEff
sudo mkdir data
sudo java -jar snpEff.jar download GRCh37.63
sudo java -jar snpEff.jar download GRCh37.64
sudo java -jar snpEff.jar download GRCh37.65
sudo java -jar snpEff.jar download hg19
cd $MYLOC

# Add SOER to tool_conf.xml
NUMBER_OF_LINES=`cat ${GALAXY_INSTALLATION}/tool_conf.xml | head -N`
NUMBER_OF_LINES=`expr ${NUMBER_OF_LINES} - 1`
cat ${GALAXY_INSTALLATION}/tool_conf.xml | head -$NUMBER_OF_LINES > tmp.conf
tool_conf.xml >> tmp.conf
echo "</toolbox>" >> tmp.conf
sudo mv -f tmp.conf ${GALAXY_INSTALLATION}/tool_conf.xm



# Setup VcfTools
sudo cp -f ../src/vcfperltools $GALAXY_INSTALLATION/tool-data/shared/

# Setup GATK
sudo mkdir $GALAXY_INSTALLATION/tool-data/shared/jars/gatk
sudo cp -f ../src/gatk/GenomeAnalysisTK.jar $GALAXY_INSTALLATION/tool-data/shared/jars/gatk/
sudo cp -Rf ../src/gatk $GALAXY_INSTALLATION/tools/

# Setup EVS
sudo cp -fR ../src/evs/ $GALAXY_INSTALLATION/tool-data/shared/jars/

# Move AlleleFreq jar files to directory
sudo mkdir $GALAXY_INSTALLATION/tool-data/shared/jars/alleleFreq
sudo cp -f ../src/getAlleleFreqSummary/GetAlleleFreqSummary.jar $GALAXY_INSTALLATION/tool-data/shared/jars/alleleFreq/

# Download Visualisation things
sudo mkdir $GALAXY_INSTALLATION/tool-data/shared/ucsc/chrom
echo "Downloading Reference Genomes for Visualisations.. this may take some time.."
sudo python $GALAXY_INSTALLATION/cron/build_chrom_db.py $GALAXY_HOME/galaxy-dist/tool-data/shared/ucsc/chrom/

# Move haploview
sudo mkdir $GALAXY_INSTALLATION/tool-data/shared/jars/haploview
sudo cp -f ../src/haplo/Haploview.jar $GALAXY_INSTALLATION/tool-data/shared/jars/haploview/

# Download 1kg allele frequency data
echo Downloading 1000genomes files... ~1.3gb..
sudo wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/ALL.wgs.phase1_integrated_calls.20101123.snps_indels_svs.sites.vcf.gz
sudo mkdir $GALAXY_INSTALLATION/tools/SOER1000genes/data/1kg
sudo mkdir $GALAXY_INSTALLATION/tools/SOER1000genes/data/1kg/vcf
sudo tabix -p vcf ALL.wgs.phase1_integrated_calls.20101123.snps_indels_svs.sites.vcf.gz
sudo cp -f ALL.wgs.phase1.integrated_calls.* $GALAXY_INSTALLATION/tools/SOER1000genes/data/1kg/vcf/

# Shift all the tools
sudo cp -fR ../galaxy/ $GALAXY_INSTALLATION/tools/SOER1000genes/

# Install dbSNP
echo "Downloading dbSNP135 (~9Gb).. This may take some time.."
echo "If you already have dbSNP and its tabix file please put them in $GALAXY_INSTALLATION/tools/SOER1000genes/data/ folder named 00-All.vcf.gz and 00-All.vcf.gz.tbi accordingly and exit the script."

sudo wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/v4.0/00-All.vcf.gz 
sudo mkdir $GALAXY_INSTALLATION/tools/SOER1000genes/data
sudo mv -f 00-All.vcf.gz $GALAXY_INSTALLATION/tools/SOER1000genes/data/dbSNP.vcf.gz
sudo tabix -p vcf $GALAXY_INSTALLATION/tools/SOER1000genes/data/dbSNP.vcf.gz

# Setup BioPerl
echo Downloading ensembl cache, ~1.8gb...
delete a line from a file bash
wget ftp://ftp.ensembl.org/pub/release-65/variation/VEP/homo_sapiens/homo_sapiens_vep_65_sift_polyphen.tar.gz
wget ftp://ftp.ensembl.org/pub/release-64/variation/VEP/homo_sapiens/homo_sapiens_vep_64_sift_polyphen.tar.gz

sudo mkdir /usr/local/ensembl_cache

tar -xzf homo_sapiens_vep_65_sift_polyphen.tar.gz
mv homo_sapiens /usr/local/ensembl_cache/
rm -f homo_sapiens_vep_65_sift_polyphen.tar.gz

tar -xzf homo_sapiens_vep_64_sift_polyphen.tar.gz
mv homo_sapiens /usr/local/ensembl_cache/
rm -f homo_sapiens_vep_64_sift_polyphen.tar.gz

sudo cp -fR ../src/bioperl-live /usr/local/
sudo cp -fR ../src/ensembl /usr/local/
sudo cp -fR ../src/ensembl-compara /usr/local/
sudo cp -fR ../src/ensembl-variation /usr/local/
sudo cp -fR ../src/ensembl-functgenomics /usr/local/
sudo cp -fR ../src/ensembl_cache /usr/local

echo 'PERL5LIB=$PERL5LIB:/usr/local/bioperl-live' >> $GALAXY_HOME/.bashrc
echo 'PERL5LIB=$PERL5LIB:/usr/local/ensembl/modules' >> $GALAXY_HOME/.bashrc 
echo 'PERL5LIB=$PERL5LIB:/usr/local/ensembl-compara/modules' >> $GALAXY_HOME/.bashrc
echo 'PERL5LIB=$PERL5LIB:/usr/local/ensembl-variation/modules' >> $GALAXY_HOME/.bashrc
echo 'PERL5LIB=$PERL5LIB:/usr/local/ensembl-functgenomics/modules' >> $GALAXY_HOME/.bashrc
echo 'PERL5LIB=$PERL5LIB:$GALAXY_INSTALLATION/tool-data/shared/vcfperltools' >> $GALAXY_HOME/.bashrc
echo "export PERL5LIB" >> $GALAXY_HOME/.bashrc

echo "TEMP=$GALAXY_INSTALLATION/database/tmp" >> $GALAXY_HOME/.bashrc;
echo "export TEMP" >> $GALAXY_HOME/.bashrc

sudo chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_INSTALLATION


echo Done!
