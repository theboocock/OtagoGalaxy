#!/bin/bash
#
# Calculates LD values for a snp from tped and tfam files.
#
# Inputs
# $1 = tped file
# $2 = tfam file
# $3 = rsid
# $4 = size of ld window
# $5 = r2 to filter out
# $6 = output filename

~/galaxy-dist/tool-data/shared/plink/./plink --tped $1 --tfam $2 --r2 --ld-snp $3 --ld-window $4 --ld-window-r2 $5 --noweb

mv -f plink.ld $6
