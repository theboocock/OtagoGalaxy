#!/bin/bash
#
#$i = INPUT gen files

FILES=$@

count=1

for f in $FILES
do
    cat $f | awk -v file=$count '{print $0 > file"_"$1"_tmp.gen"}' & 
    count=$((count + 1))

done

wait

