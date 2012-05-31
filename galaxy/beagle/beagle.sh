#!/bin/bash
#
# Wrapper for beagle analysis
# @author James Boocock
#
# $1 impute, ibd or assoctest $2 command line argument
#
PREFIX=`date '+%s'`
COMMAND="${1} out=$PREFIX"
eval $COMMAND > /dev/null
mv $PREFIX.log $2
gunzip $PREFIX.*.phased.gz
mv $PREFIX.*.phased $3


