#!/bin/bash
# $1 = ped
# $2 = map
# $3 = output file

~/galaxy-dist/tools/SOER1000genes/galaxy/beagle/./ped_to_bgl $1 $2 > $3 2> /dev/null

