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
# $12 = root_dir
# $13 = allow_large_regions

if [ "$9" == "unphased" ] ; then

    PHASE="-g"

else

    PHASE="-known_haps_g"

fi

     
    START=`head -1 $4 | awk '{print $3}' `
    END=`tail -1 $4| awk '{print $3}' `
    impute2 -allow_large_regions\
    -m ${12}/tools/OtagoGalaxy/data/1kg/impute2/genetic_map_chr${3}_combined_b37.txt \
    -h ${12}/tools/OtagoGalaxy/data/1kg/impute2/ALL_1000G_phase1integrated_v3_chr${3}_impute.hap \
    -l ${12}/tools/OtagoGalaxy/data/1kg/impute2/ALL_1000G_phase1integrated_v3_chr${3}_impute.legend \
    $PHASE $4 -int $START $END -Ne ${10} -buffer ${11} -o $5 \
    -r $6 -w $7 -i $8 -os 0 1 2 3 > /dev/null



