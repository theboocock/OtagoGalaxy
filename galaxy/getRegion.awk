#!/bin/bash
# Author: Edward Hills
# Date: 29/11/11
#
# This script will find the first line that does not contain a # comment
# and echo out the chromosome followed by a : followed by a - separated
# pair of regions. ie chromosome:startRegion-endRegion.
#
# Example use is cat inputFile.vcf | ./getRegion inputFile.vcf

awk '
    {if ($1 !~ /'#'/)
        {print $1":"$2}
    }
    ' > ~tmp.tmp

FIRST_LINE=`head -1 ~tmp.tmp`

tail -1 $1 | awk '{print $2}' >> ~tmp.tmp

SECOND_LINE=`tail -1 ~tmp.tmp`

echo $FIRST_LINE"-"$SECOND_LINE

rm -f ~tmp.tmp
