#!/bin/bash

#
# Run dbsnp.pl
#
# --- TESTING - MEDIUM ---
#
# PLEASE CHECK FOR WARNING AND ERROR MESSAGES IN OUTPUT
#

options_file=test_mouse_quick.opt

#
# SUGGESTION: COMMENT OUT THE FOLLOWING LINES AND ENTER YOUR DATABASE
#

#database=

#rm -rf $database/*
#mysqladmin --force drop $database
#mysqladmin create $database

dbsnp.pl getorg     --options-file=$options_file
dbsnp.pl getbuild   --options-file=$options_file
dbsnp.pl download   --options-file=$options_file
dbsnp.pl load       --options-file=$options_file
dbsnp.pl runscript  --options-file=$options_file
dbsnp.pl log        --options-file=$options_file
