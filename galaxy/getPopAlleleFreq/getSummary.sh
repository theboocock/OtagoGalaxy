#!/bin/bash
#
# Author: Ed Hills
# Date: 27/01/12
#
# This file will scan through the outputted whole vcf and return
# a txt file with minimal information highlighting the allele frequencies
# per population.
#
# Inputs
# $1 = Input File to scan

#`cat $1 | awk -F [\;] '
#if (
#    '`
