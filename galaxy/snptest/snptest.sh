#!/bin/bash

sample1=$1
sample2=$3
output=$#

for f in 1_*_tmp.gen
do
    COMMAND="snptest -summary_stats_only -data $f $sample1"
    if [ "$2" == "sample2" ]
    then
        s=${f:2}
        COMMAND=$COMMAND" 2_$s $sample2"
    fi
    COMMAND=$COMMAND" -overlap -o $output"
done

$COMMAND

