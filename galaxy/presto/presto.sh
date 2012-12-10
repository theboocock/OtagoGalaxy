#!/bin/bash

missing=$1
trait=$2
ranks=$5
seed=$6
nperms=$7
threshold=$8
dips=$9


strata=""
if [ "$3" != "None" ] ; then
    strata="strata=$3"
fi

assocs=""
if [ "$4" != "None" ] ; then
    split=`echo $4 | tr -d ','`
    assocs="test=$split"
fi

num_files=$#

files=""
for ((i=10; i<=$num_files; i++)) {
    file=${10}
    files=$files"$file"
    shift
}

echo $1, $2, $3, $4, $5, $6, $7, $8, $9, $9
echo $files

java -jar ~/galaxy-dist/tool-data/shared/jars/presto/presto.jar out=out missing=$missing trait=$trait $strata $assocs $ranks $seed $nperms $threshold $dips $files 

