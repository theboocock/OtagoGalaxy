#!/bin/bash
#
# Wrapper for beagle analysis
# @author James Boocock
#
# $1 impute, ibd or assoctest $2 command line argument
#
PREFIX=`date '+%s'`
GPROBS_FILE=''
DOSE_FILE=''
LOGFILE=''
PHASED=''
RSQUARED_FILE=''

while getopts "l:c:p:g:d:r:" opt; do
case $opt in
c)
COMMAND="${OPTARG} out=$PREFIX"
;;
l)
LOGFILE=$OPTARG
;;
p)
PHASED=$OPTARG
;;
g)
GPROBS_FILE=$OPTARG
;;
d)
DOSE_FILE=$OPTARG
;;
r)
RSQUARED_FILE=$OPTARG
;;
esac
done

if [ "${COMMAND}" != "" ]; then
eval $COMMAND > /dev/null
fi

if [ "${LOGFILE}" != "None" ]; then
     mv $PREFIX.log $LOGFILE
fi

if [ "${PHASED}" != "None" ]; then
gunzip $PREFIX.*.phased.gz
mv $PREFIX.*.phased $PHASED
gunzip $PREFIX.*.gprobs.gz
mv $PREFIX.*.gprobs $GPROBS_FILE
gunzip $PREFIX.*.dose.gz
mv $PREFIX.*.dose $DOSE_FILE
mv $PREFIX.*.r2 $RSQUARED_FILE
fi


#mv $PREFIX.log $2
#gunzip $PREFIX.*.phased.gz
#mv $PREFIX.*.phased $3


