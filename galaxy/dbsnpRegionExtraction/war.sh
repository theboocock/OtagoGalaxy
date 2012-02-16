#!/bin/bash

for f in chr*
do
while read line
do
    tabix ~/galaxy-dist/tools/SOER1000genes/data/dbSNP.vcf.gz ${line} >> $f-reg
done < $f
done

for f in *-reg*
do
    cat $f | awk '{print $3}' > $f-snplist
done

rm -f chr*-reg
