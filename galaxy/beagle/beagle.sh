#!/bin/bash
#
# Wrapper for beagle analysis
# @author James Boocock
#
#
PREFIX=`date '+%s'`

usage(){
	cat << EOF
	Usage: This bash script sets up and runs beagle for 
	       various settings for use within the galaxy 
	       environment.
	
	-c <command> command line argument to execute.
	-l <file> log file path within galaxy.
	-n <path> Directory to place files extra files beagle produces.
	-p If phased output is to be created.
	-i <id> Id of the log file galaxy uses to identify extra produced
		files.
	-g If gprobs=true in the command. More files are created when this
	   option is selected.
	-f fast IBD calculation
	-h HBD calculation
	-b IBD calculation requiring IBD pairs file
	-a association test
	-m Markers file is specified.
	-I <number> number of input files
	-t trait specified
	-d comma seperated list containing history dataset names.
	-D comma seperated list containing dataset names used for matching
EOF
}


get_history_id(){
 IFS=','
 I=0
 GET_HISTORY_ID=`echo $GET_HISTORY_ID |   awk -F [\.] '{ print $2 }'`
GET_HISTORY_ID=$GET_HISTORY_ID.dat
 for word in $DATASET_STRING
 do
	TEMP=`echo $word | awk -F [\/] '{ print $NF }'`
	
	if [ "$TEMP" != "$GET_HISTORY_ID" ]; then
		I=$((I+1))		 
	else
	break
	fi
done
 J=0
 echo $I
 for word in $HISTORY_STRING
 do
	if [ "$J" != "$I" ]; then
		J=$((J+1))	
 	else
	HISTORY_ID=$word
	break
	fi
 done
}


getoptions(){
while getopts "d:D:I:l:c:n:i:pgfhbamt" opt; do
case $opt in
c)
COMMAND="${OPTARG} out=$PREFIX"
;;
l)
LOGFILE=$OPTARG
;;
n)
NEW_FILE_PATH=$OPTARG
;;
p)
PHASED_FILE='TRUE'
;;
g)
GPROBS='TRUE'
;;
i)
ID=$OPTARG
;;
t)
TRAIT='TRUE'
;;
d)
HISTORY_STRING=$OPTARG
;;
D)
DATASET_STRING=$OPTARG
;;
f)
FAST_IBD='TRUE'
;;
h)
HBD='TRUE'
;;
b)
IBD='TRUE'
;;
a)
ASSOCIATON_TEST='TRUE'
;;
m)
MARKERS='TRUE'
;;
I)
echo $OPTARG
COUNT=$OPTARG
;;
?)
usage
exit 1
;;
esac
done
}
checkmarkers(){
if [ -z "${MARKERS}" ]; then
	if [ "$HBD" == "TRUE" ] || [ "$IBD" == "TRUE" ]; then
		echo " markers file with cM positions is required if \"estimatehbd=true\" r if an ibdpairs file is specified" 1>&2
		exit 2	
	fi
	echo $COUNT
	if [ "$COUNT" -gt  "1" ]; then
		echo "You need to specify a markers file if you have multiple beagle files as inputs" 1>&2
		exit 2
	fi
fi
}

runbeagle(){
if [ "${COMMAND}" != "" ]; then
eval $COMMAND > /dev/null
fi
}

movefiles(){
if [ "$LOGFILE" != "" ]; then
     mv $PREFIX.log $LOGFILE
fi
if [ "$ASSOCIATON_TEST" == "TRUE" ]; then
        gunzip $PREFIX.*.dag.gz
	mv $PREFIX.*.dag ${NEW_FILE_PATH}/primary_${ID}_dag_visible_dag
	if [ "$TRAIT" == "TRUE" ]; then
		mv $PREFIX.*.null ${NEW_FILE_PATH}/primary_${ID}_null_visible_null
		mv $PREFIX.*.pval ${NEW_FILE_PATH}/primary_${ID}_pval_visible_pval
	fi


elif [ "$PHASED_FILE" == "TRUE" ]; then
	gunzip $PREFIX.*.phased.gz
	for f in $PREFIX.*.phased
	do
	GET_HISTORY_ID=$f
	get_history_id
	mv $f ${NEW_FILE_PATH}/primary_${ID}_phased${HISTORY_ID}_visible_bgl
	done
fi

if [ "$GPROBS" == "TRUE" ]; then
	gunzip $PREFIX.*.gprobs.gz
	gunzip $PREFIX.*.dose.gz
	
	for f in $PREFIX.*.gprobs
	do
	GET_HISTORY_ID=$f
	get_history_id
	mv $f ${NEW_FILE_PATH}/primary_${ID}_gprobs${HISTORY_ID}_visible_gprobs
	done 

	for f in $PREFIX.*.dose
	do
	GET_HISTORY_ID=$f
	get_history_id
	mv $f ${NEW_FILE_PATH}/primary_${ID}_dose${HISTORY_ID}_visible_dose
	done
	
	for f in $PREFIX.*.r2
	do
	GET_HISTORY_ID=$f
	get_history_id
	mv $f   ${NEW_FILE_PATH}/primary_${ID}_rsquared${HISTORY_ID}_visible_r2
	done
fi

if [ "$FAST_IBD" == "TRUE" ]; then
	gunzip $PREFIX.*.fibd.gz
	for f in $PREFIX.*.fibd
	do
	GET_HISTORY_ID=$f
	get_history_id
	mv $f   ${NEW_FILE_PATH}/primary_${ID}_fibd${HISTORY_ID}_visible_fibd
	done
fi
if [ "$HBD" == "TRUE" ]; then
	gunzip $PREFIX.*.hbd.gz	
	for f in $PREFIX.*.hbd
	do
	GET_HISTORY_ID=$f
	get_history_id
	mv $f   ${NEW_FILE_PATH}/primary_${ID}_hbd${HISTORY_ID}_visible_hbd
	done
fi
if [ "$IBD" == "TRUE" ]; then
	for f in $PREFIX.*.ibd
	do
	GET_HISTORY_ID=$f
	get_history_id
	mv $f   ${NEW_FILE_PATH}/primary_${ID}_ibd${HISTORY_ID}_visible_ibd
	done
	
fi
}

getoptions "$@"
echo $COMMAND
checkmarkers 
runbeagle
movefiles
