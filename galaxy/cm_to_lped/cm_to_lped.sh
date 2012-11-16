#!/bin/bash

# Simple script that annotates the centimorgans from the hapmap centimorgan map.
#
#
# $1 extrafiles path
# $2 basename
# $3 galaxy impute data folder containing the centimorgan files
# $4 galaxy root dir
#

cp $1/$2.ped $2.ped 

cat $1/$2.map | awk '{print $1}' | uniq > chromosomes


while read line
do
    CHROM=$line
    MAP_FILE=${3}/genetic_map_chr${line}_combined_b37.txt 
    echo $MAP_FILE    
    python $4/tools/SOER1000genes/galaxy/cm_to_lped/annotate_cm.py $MAP_FILE "${1}/${2}.map" >> out.tmp
done < chromosomes

cp out.tmp $1$2

