#!/bin/bash
#
# Calculates LD values for a snp from tped and tfam files.
#

~/galaxy-dist/tool-data/shared/plink/./plink --tped $1 --tfam $2 --r2 --ld-snp $3 --ld-window $4 --ld-window-r2 $5 --noweb

mv -f plink.ld $6
