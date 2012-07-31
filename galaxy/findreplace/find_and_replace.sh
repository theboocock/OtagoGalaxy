#!/bin/bash

#
# $1 find
# $2 replace
# $3 input
# $4 output

# replace for tab escape character
replace=`echo "${2}" | sed -e 's/'TAB'/\t/'`
echo "$replace"
input=$1
export replace
export input
#export so perl can access the enviroment variables
perl -p -e 's/$ENV{'input'}/$ENV{'replace'}/ ' $3 > $4

exit 0
