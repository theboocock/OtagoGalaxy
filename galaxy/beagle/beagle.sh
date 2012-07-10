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

EOF
}
getoptions(){
while getopts "I:l:c:n:i:pgfhbam" opt; do
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
	if [ $COUNT -gt  1 ]; then
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
	echo "${NEW_FILE_PATH}"
if [ "$LOGFILE" != "" ]; then
     mv $PREFIX.log $LOGFILE
fi
if [ "$ASSOCIATON_TEST" == "TRUE" ]; then
	echo "ASSOC SELECTED"	



elif [ "$PHASED_FILE" == "TRUE" ]; then
	i=0
	gunzip $PREFIX.*.phased.gz
	for f in $PREFIX.*.phased
	do
	echo $f
	mv $f ${NEW_FILE_PATH}/primary_${ID}_phased${i}_visible_bgl
	let i=I+1
	done
fi

if [ "$GPROBS" == "TRUE" ]; then
	i=0
	gunzip $PREFIX.*.gprobs.gz
	gunzip $PREFIX.*.dose.gz
	for f in $PREFIX.*.gprobs
	do
	mv $f ${NEW_FILE_PATH}/primary_${ID}_gprobs${i}_visible_bgl
	let i=i+1
	done 
	i=0
	for f in $PREFIX.*.dose
	do
	mv $f ${NEW_FILE_PATH}/primary_${ID}_dose${i}_visible_bgl
	let i=i+1
	done
	i=0
	for f in $PREFIX.*.r2
	do
	mv $f   ${NEW_FILE_PATH}/primary_${ID}_r2${i}_visible_bgl
	let i=i+1
	done
fi

if [ "$FAST_IBD" == "TRUE" ]; then
	gunzip $PREFIX.*.fibd.gz
	mv $PREFIX.*.fibd ${NEW_FILE_PATH}/primary_${ID}_fibd_visible_bgl
fi

}

getoptions "$@"
checkmarkers
echo $COMMAND
runbeagle
movefiles
