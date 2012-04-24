#!/bin/bash
#
# @Author: Ed hills
# @Date: 20/01/12
#
# This will run the setup script that will sort out where snpEff has to go etc.
#

echo Setting up snpEff...
# Move snpEff.jar and SnpSift.jar into the proper galaxy location
cp -f *.jar /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff/

# Move config file into proper location
cp -f snpEff.config /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff/

# Move snpEff.xml into its rightful place
cp -f galaxy/snpEff.xml /home/galaxy/galaxy-dist/tools/snpEff
cp -f galaxy/snpSift_annotate.xml /home/galaxy/galaxy-dist/tools/snpEff
cp -f galaxy/snpSift_filter.xml /home/galaxy/galaxy-dist/tools/snpEff

# Move scripts folder to jar location
cp -fR scripts/ /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff

echo Done!
