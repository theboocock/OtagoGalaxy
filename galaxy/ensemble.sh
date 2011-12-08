#!/bin/bash
# Author: Edward Hills and James Boocock
# Date: 8/12/2011
#
#Script takes and runs the variant effect predictor
#from ensemble
#
# Inputs
#$1 input file
#$2 output file

perl variant_effect_predictor.pl -i $1 -o $2 --check_existing --gene \
                        --cache --dir "/usr/local/ensembl_cache" \
                        --poly b --sift b --hgvs --force_overwrite

