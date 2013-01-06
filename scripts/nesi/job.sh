#!/bin/bash
#
# This script is used due to NeSI's lack of support for redirection.
#
# INPUTS
# $1 = command to be run
# $2 = output file
# 
# e.g. cat this_file.txt > that_file.txt would be run as 
#       ./job.sh "cat this_file.txt" that_file.txt
#
# FIXME: YUCK - no can do

while getopts "c:o:e:" opt; do
    case $opt in
        c)
         commandline=$OPTARG
         ;;
        o)
         output_file=$OPTARG
         ;;
        e)
         error_file=$OPTARG
         ;;
        ?)
         echo "Invalid option" >&2
         exit 1
         ;;
    esac
done

if [ "$error_file" != "" ]; then
    $commandline > $output_file 2> $error_file
else
    $commandline > $output_file
fi
