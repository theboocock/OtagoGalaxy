#!/bin/bash
#
# Runs the impute2 program with files specified.
# TODO should have 1kg files symlinked not hard coded
# 
# INPUTS
# $1 = start pos
# $2 = end pos
# $3 = chr number of file
# $4 = file of known haps (mydata.hap)
# $5 = geno file
# $6 = summary file
# $7 = warnings file
# $8 = info file
# $9 = phased or not
# $10 = Ne
# $11 = buffer_size

java GenerateImputePairs $1 $2 > ~generated.tmp

if [ "$9" == "unphased" ] ; then

    PHASE="-g"

else

    PHASE="-known_haps_g"

fi

while read line
do

    START=`echo $line | awk '{print $1}' `
    END=`echo $line | awk '{print $2}' `
    
    impute2 \ 
    -m ~/galaxy-dist/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/genetic_map_chr${3}_combined_b37.txt \ 
    -h ~/galaxy-dist/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${3}_impute.hap \ 
    -l ~/galaxy-dist/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${3}_impute.legend \ 
    $PHASE $4 -int ${START}e6 ${END}e6 -Ne ${10} -buffer ${11} -o $5 \ 
    -r $6 -w $7 -i $8 -os 0 1 2 3

done < ~generated.tmp

rm ~generated.tmp

exit 0
