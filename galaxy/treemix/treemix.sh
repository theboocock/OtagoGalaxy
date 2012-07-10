#!/bin/bash
#
# first gzips input file (as galaxy currently doesn't allow gzipped files)
# and then runs treemix
# 
# $1 input file name
# $2 output_cov
# $3 output_covse
# $4 output_modelcov
# $5 output_treeout
# $6 output_vertices
# $7 output_edges

gzip -c $1 > $1.gz

treemix -i $1.gz -i galaxy_treemix

# need to unzip these files before moving them to glaxy. 
mv -f *.cov.* $2
mv -f *.covse.* $3
mv -f *.modelcov.* $4
mv -f *.treeout.* $5
mv -f *.vertices.* $6
mv -f *.edges.* $7
