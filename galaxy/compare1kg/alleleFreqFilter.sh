#!/bin/bash
#
# Filters VCF file by allele frequency 
# removes lines that do not contain AF column
#
# $1 file
# $2 threshold below which to throw away line


while read line
do
    TEMP_LINE=`echo $line | awk '{if($8 ~ /AF=/){print $8}}'`
    if [ "$TEMP_LINE" != "" ] ;then
        AF_CHECK=`echo $TEMP_LINE | awk -F[\;] '{ for (i=1;i<= NF;i++) {                if ($i ~/AF=/){print $i}}}'`
        if ["$AF_CHECK" != "" ]; then
            AF_NUMBER=`echo $AF_CHECK | awk -v AF=$2 -F[\=] '{if($2 >= AF){print{$0}}}'`
            if ["$AF_NUMBER" != 0 ];then
                    echo $line
                fi
            fi
    fi
done < $1

    

