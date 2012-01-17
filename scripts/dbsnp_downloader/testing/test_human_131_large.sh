#!/bin/bash

#
# Run dbsnp.pl
#
# --- TESTING - LARGE ---
#

options_file=test_human_131_large.opt

dbsnp.pl getorg     --options-file=$options_file
dbsnp.pl getbuild   --options-file=$options_file
dbsnp.pl download   --options-file=$options_file
dbsnp.pl load       --options-file=$options_file
dbsnp.pl runscript  --options-file=$options_file
dbsnp.pl log        --options-file=$options_file
