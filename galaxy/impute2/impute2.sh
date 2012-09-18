#!/bin/bash
#
# $1 = start pos
# $2 = end pos
# $3 = chr number of file
# $4 = file of known haps (mydata.haps)
# $5 = geno file
# $6 = summary file
# $7 = warnings file
# $8 = info file

java GenerateImputePairs $1 $2 > ~generated.tmp

while read line
do

    START=`echo $line | awk '{print $1}' `
    END=`echo $line | awk '{print $2}' `
    
    impute2 \ 
    -m ~/galaxy-dist/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/genetic_map_chr${3}_combined_b37.txt \ 
    -h ~/galaxy-dist/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${3}_impute.hap \ 
    -l ~/galaxy-dist/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${3}_impute.legend \ 
    -known_haps_g $4 -int ${START}e6 ${END}e6 -Ne 20000 -buffer 250 -o $5 \ 
    -r $6 -w $7 -i $8 -os 0 1 2 3

done < ~generated.tmp

rm ~generated.tmp

exit 0
