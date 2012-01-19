INPUTS=`echo $2 | tr "," " "`
/home/galaxy/galaxy-dist/tools/SOER1000genes/galaxy/ensemblVEP/./ensembl_run.sh $1 $INPUTS
