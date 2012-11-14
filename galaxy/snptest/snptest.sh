#!/bin/bash
# Author: Edward Hills
# Description: Runs snptest 

sample1=$1
sample2=$3
eval output=\$$#

# go through each file
for f in 1_*_tmp.gen
do
    COMMAND="snptest -summary_stats_only -data $f $sample1"
    if [ "$2" == "sample2" ]
    then
        s=${f:2}
        COMMAND=$COMMAND" 2_$s $sample2 -overlap"
    fi
    COMMAND=$COMMAND" -o $output"

    # run it
    $COMMAND &
done


exit 0
