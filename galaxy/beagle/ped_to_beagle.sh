#!/bin/bash
# $1 = extrafiles path
# $2 = metadata base name
# $3 = output file

~/galaxy-dist/tools/SOER1000genes/galaxy/beagle/./ped_to_bgl $1/$2.ped $1/$2.map > $3 
