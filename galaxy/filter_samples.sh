#!/bin/bash

SAMPLE_LIST=""
NUM_SAMPLES=$#

for ((i=1; i<NUM_SAMPLES; i++))
do
    eval INPUT=\$${i}
    SAMPLE_LIST="${SAMPLE_LIST}, $INPUT"
done
echo $SAMPLE_LIST
