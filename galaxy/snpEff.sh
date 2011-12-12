#!/bin/bash
#file downloads Gene sequence if it is not already in the SNPEFF data folder
#$1 genomeVersion
#$2 Config file


if [ ! -d "/home/galaxy/tool-data/shared/jars/snpEff/data/$5" ]
then
    java -jar  ~/galaxy-dist/tool-data/shared/jars/snpEff/snpEff.jar download $1 -c $2
fi



