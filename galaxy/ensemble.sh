#!/bin/bash
# Author: Edward Hills and James Boocock
# Date: 8/12/2011
#
# Script takes and runs the variant effect predictor
# from ensemble
#
# Inputs
# $1 = input file
#

perl ~/galaxy-dist/tools/SOER1000genes/galaxy/variant_effect_predictor.pl -i $1 -o ~ensemble-TMP.tmp --check_existing --gene \
                        --cache --dir "/usr/local/ensembl_cache" \
                        --poly b --sift b --hgvs --force_overwrite > /dev/null

cat ~ensemble-TMP.tmp
rm -f ~ensemble-TMP.tmp

