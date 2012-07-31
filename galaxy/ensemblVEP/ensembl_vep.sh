#!/bin/bash
#
# EnsemblVEP splits input from galaxy textboxes into space seperated list
#
# @author James Boocock
#

INPUTS=`echo $2 | tr "," " "`
~/galaxy-dist/tools/SOER1000genes/galaxy/ensemblVEP/./ensembl_run.sh $1 $INPUTS

exit 0
