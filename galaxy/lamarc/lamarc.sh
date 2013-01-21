#!/bin/bash
#
# Author: Edward Hills
# Date: 31/05/12
# Description: This wrapper will take the commands that have been 
#              specified from the xml, devise a way of how the 
#              program would be run interactively. Save those 
#              commands in a txt file then pass the interactive 
#              program the file containing those commands. May end 
#              up very difficult. 
#
# Inputs:
# $1 = Main input file

INPUT=""
COMMAND=$1'\nI\nV\n\n'

for ((i=5; i <= $#; i++))
do  

    eval INPUT=\${$i}

    if [ "$INPUT" == "enter" ]
    then
        INPUT='\n'
    fi
    
    if [ "$INPUT" == "run" ]
    then
        INPUT="."
    fi

    COMMAND=$COMMAND'\n'$INPUT        

done

echo -e $COMMAND > ~tmp.tmp

~/galaxy-dist/tools/OtagoGalaxy/galaxy/lamarc/lamarc/./lamarc < ~tmp.tmp > ~stderr.tmp

mv -f *outfile*.txt $2
mv -f report.xml $3
mv -f *tracefile*.txt $4

exit 0
