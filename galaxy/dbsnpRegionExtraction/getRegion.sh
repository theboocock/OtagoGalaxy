#!/bin/bash
# Author: Edward Hills
# Date: 8/2/12
#
# GetRegion will return all start and end positions for each chromosome
# in the file given. The file must be sorted by chromosome as it will
# not be able to match regions which have chromosomes not in order.
# It will return each region in the format below
# 
#   chr#:startPos..endPos
# 
# for each list of chromosomes.
#
# Example use is cat inputFile.vcf | ./getRegion inputFile.vcf
#
# Inputs 
# $1 = input_file

count=1
curr_chr=""
curr_pos=""
prev_chr=""
prev_pos=""
firstReg=""

while read line 
do
    curr_chr=`echo $line | awk '{if ($1 !~ /'#'/)
                                    {print $1}
                               }'`

    curr_pos=`echo $line | awk '{if ($1 !~ /'#'/)
                                    {print $2}
                               }'`


    if [ $count != 1 -a "$curr_chr" != "$prev_chr" ]
    then
        echo "$firstReg..$prev_pos" >> ~reg.tmp
        count=1
    fi

    if [ $count == 1 ]
    then
        firstReg="$curr_chr:$curr_pos"
    fi
   
    prev_chr=$curr_chr
    prev_pos=$curr_pos

    if [ "$curr_chr" != "" ]
    then
        count=$((count + 1))
    fi

done < $1
    
# print final line as it wont be printed above
echo "$firstReg..$prev_pos" >> ~reg.tmp
