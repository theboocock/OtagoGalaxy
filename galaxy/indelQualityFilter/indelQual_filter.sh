#!/bin/bash
#
# @Author: Ed Hills
# @Date: 10/01/12
#
# Runs SnpSift and will filter input vcf based on quality score given.
#
# Inputs
# $1 = Input VCF
# $2 = Quality Score
#

cat $1 | java -jar /home/galaxy/galaxy-dist/tool-data/shared/jars/snpEff/SnpSift.jar filter "((exists INDEL) & (QUAL >= ${2}))"

exit 0
