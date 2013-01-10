#!/bin/bash
#
# This script is used due to NeSI's lack of support for redirection.
#
# INPUTS
# $1 = command to be run
# $2 = output file
# 
# e.g. cat this_file.txt > that_file.txt 2> err.stderr would be run as 
#       ./job.sh -c "cat this_file.txt" -o that_file.txt -e err.stderr
#

OUTPUT=0
ERROR=0
commandline=""

while getopts "c:o:e:" opt; do
    case $opt in
        c)
         commandline=$OPTARG
         ;;
        o)
         output_file=$OPTARG
         OUTPUT=1
         ;;
        e)
         error_file=$OPTARG
         ERROR=1
         ;;
        ?)
         echo "Invalid option" >&2
         exit 1
         ;;
    esac
done


if [ $OUTPUT == 1 ] && [ $ERROR == 1 ]; then
    $commandline > $output_file 2> $error_file
elif [ $OUTPUT == 1 ] && [ $ERROR == 0 ]; then
    $commandline > $output_file
elif [ $OUTPUT == 0 ] && [ $ERROR == 1 ]; then
    $commandline 2> $error_file
else
    $commandline
fi
