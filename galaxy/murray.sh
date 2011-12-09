PL="illumina"
PU=`awk -F[:] '{print $3}' $FILE`
PU=`awk -F[_] '{print $1}' $FILE`
