#!/bin/bash
#
# Runs the impute2 program with files specified.
# TODO should have 1kg files symlinked not hard coded
# 
# INPUTS
# $3 = chr number of file
# $4 = file of known haps (mydata.hap)
# $5 = geno file
# $6 = summary file
# $7 = warnings file
# $8 = info file
# $9 = phased or not
# $10 = Ne
# $11 = buffer_size
# $12 = root_dir
# $13 = allow_large_regions


if [ "$9" == "unphased" ] ; then

    PHASE="-g"

else

    PHASE="-known_haps_g"

fi
    START=`head -1 $2 | awk '{print $3}' `
    END=`tail -1 $2| awk '{print $3}' `
    impute2 -allow_large_regions\
    -m ${10}/tools/OtagoGalaxy/data/1kg/impute2/genetic_map_chr${1}_combined_b37.txt \
    -h ${10}/tools/OtagoGalaxy/data/1kg/impute2/ALL_1000G_phase1integrated_v3_chr${1}_impute.hap \
    -l ${10}/tools/OtagoGalaxy/data/1kg/impute2/ALL_1000G_phase1integrated_v3_chr${1}_impute.legend \
    $PHASE $2 -int $START $END -Ne ${8} -buffer ${9} -o $3 \
    -r $4 -w $5 -i $6 -os 0 1 2 3 



