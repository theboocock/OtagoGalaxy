#!/bin/sh

./scripts/queue.pl 22 24 15 ./scripts/queue_build.txt

grep "CDS check" *.stdout | cut -f 3- -d : | grep -v "^$" | sort | tee cds_check.txt
grep "Protein check" *.stdout | cut -f 3- -d : | grep -v "^$" | sort | tee protein_check.txt

 
