#!/bin/bash
#
wget http://evs.gs.washington.edu/evs_bulk_data/ESP6500SI.snps_indels.vcf.tar.gz
gunzip ESP6500SI.snps_indels.vcf.tar.gz
tar xvf ESP6500SI.snps_indels.vcf.tar
mkdir eps
mv EP*.vcf eps/
cd eps/

