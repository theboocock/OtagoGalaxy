#!/bin/bash
#Script takes and runs the variant effect predictor
#from ensemble

#$1 input file
#$2 output file

perl variant_effect_predictor.pl -i $1 -o $2 --check-exiting --gene \
                        --gene --cache --dir /usr/local/ensemblecache \
                        --poly b --sift b --hgus
