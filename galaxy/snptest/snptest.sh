#!/bin/bash

sample1=$1
sample2=$2
output=$#
file1_num_chrom=`ls 1_*_tmp.gen | wc -l`

for f in 1_*_tmp.ge
do
    COMMAND="snptest -summary_stats_only -data $f $sample1"
    if [ "$sample2" != "none" ]
    then
        s=${f:3}
        COMMAND=$COMMAND" 2_$s $sample2"
    fi
    COMMAND=$COMMAND" -overlap -o $output"
done

