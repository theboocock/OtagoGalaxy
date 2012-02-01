INPUTS=`echo $2 | tr "," " "`
~/galaxy-dist/tools/SOER1000genes/galaxy/ensemblVEP/./ensembl_run.sh $1 $INPUTS
