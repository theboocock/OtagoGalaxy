#!/bin/bash
#
# Wrapper for beagle analysis
# @author James Boocock
#
# $1 impute, ibd or assoctest $2 command line argument
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



EOF
}
getoptions(){
echo "hello"
while getopts "l:c:n:i:pg" opt; do
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
?)
usage
exit 1
;;
esac
done
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

if [ "$PHASED_FILE" == "TRUE" ]; then
	gunzip $PREFIX.*.phased.gz
	mv $PREFIX.*.phased ${NEW_FILE_PATH}/primary_${ID}_phased_visible_bgl
fi

if [ "$GPROBS" == "TRUE" ]; then
	gunzip $PREFIX.*.gprobs.gz
	mv $PREFIX.*.gprobs ${NEW_FILE_PATH}/primary_${ID}_gprobs_visible_bgl
	gunzip $PREFIX.*.dose.gz
	mv $PREFIX.*.dose ${NEW_FILE_PATH}/primary_${ID}_dose_visible_bgl
	mv $PREFIX.*.r2   ${NEW_FILE_PATH}/primary_${ID}_r2_visible_bgl
fi

}
getoptions "$@"
runbeagle
movefiles

