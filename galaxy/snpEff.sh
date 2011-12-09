#!/bin/bash
#file downloads Gene sequence if it is not already in the SNPEFF data folder
#
#$1 udlength
#$2 filterIn
#$3 filterHomeHet
#$4 statsFile
#$5 genomeVersion
#$6 input
#$7 output
#$8 filterOut
#$9 config file

if [ ! -d "/home/galaxy/tool-data/shared/jars/snpEff/data/$5" ]
then
    java -jar ~/galaxy/tool-data/shared/jars/snpEff/snpEff.jar download $5
    # Suppress output so user isnt bothered
fi

# Put this back in the xml file and just do the script stuff perhaps
java -Xmx6G -jar ~/galaxy-dist/tool-data/shared/jars/snpEff/snpEff.jar -c $9 -i vcf -o vcf -upDownStreamLen $1 $2 $3  
     -no $8 -stats $4 $5 $6 > $7 


