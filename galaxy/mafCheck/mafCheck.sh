#!/bin/bash
#
# Author: Ed Hills
# Date: 7/02/12
#
# This will check down the AC/AN column and check whether the minor
# allele frequency is more common than the ref allele and return all
# those that have the minor allele more common.
#
# Inputs
# $1 - VCF
# $2 - Output file

COL_CHECK_COUNT=0
AC=""
AN=""

while read line
do  
    orig_line=$line
    echo $line | awk '{if ($1 ~ /^#/) {print $0}}' >> $2
    line=`echo $line | awk '{print $8}'`
    AC=`echo $line | awk -F [\;] '{ for (i=1; i<=NF; i++) 
                                    {if ($i ~ /^AC/) 
                                        {print $i}
                                    }
                                  }'`
    AN=`echo $line | awk -F [\;] '{ for (i=1; i<=NF; i++) 
                                    {if ($i ~ /^AN/) 
                                        {print $i}
                                    }
                                  }'`
    AC=`echo $AC | awk -F[\=] '{print $2}'`
    AN=`echo $AN | awk -F[\=] '{print $2}'`
    
    if [ "$AC" != "" -a "$AN" != "" ] 
    then
        COL_CHECK_COUNT=1
        AN=$((AN/2))
        NUM=`echo $AC | awk -F[\,] '{print NF}'`
        AC_PART=$AC
        for ((i=1; i<=$NUM; i++)) 
        do
            AC_PART=`echo $AC | awk -F[\,] -v i=$i '{print $i}'`
            if [ "$AC_PART" -gt "$AN" ] 
            then
                echo $orig_line >> $2
                break
            fi
        done
    fi
done < $1

if [ $COL_CHECK_COUNT == 0 ]
then
    echo "Please check there is an AC and AN columns present in the VCF. Alternatively there may not be any cases where the ALT allele is more frequent than the REF allele"
fi

exit 0
