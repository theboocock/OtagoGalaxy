#!/bin/bash

awk '
    {if ($1 !~ /'#'/)
        {print $1":"$2}
        exit
    }
    ' > ~tmp.tmp

FIRST_LINE=`head -1 ~tmp.tmp`

tail -1 $1 | awk '{print $1 $2}' >> ~tmp.tmp

SECOND_LINE=`tail -1 ~tmp.tmp`

echo $FIRST_LINE "-" $SECOND_LINE
