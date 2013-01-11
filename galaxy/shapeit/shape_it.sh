#!/bin/bash
#
# This script will run shapeit with the values passed from shape_it.xml
# It will determine the correct map file for this chromosome and assume
# the input file has already been split into chromosomes.
# For performance reasons it will also have a default value of 2 threads.
#
# INPUTS
# $1 = gen
# $2 = sample
# $3 = threshold
# $4 = from (optional)
# $5 = to (optional but linked with $5
# $6 = to use 1kg ref or not (optional)
# $6 = output - haps
# $7 = output - sample
# $8 = chromosome

while getopts "l:c:g:s:m:rf:t:h:o:R:" opt; do
    case $opt in
        g)
            INPUT_GEN=$OPTARG
        ;;
        s)
            INPUT_SAMPLE=$OPTARG
        ;;
        m)
            THRESHOLD=$OPTARG
        ;;
        r)
            REF="--input-ref $REF_HAP $REF_LEGEND $REF_SAMPLE"
        ;;
        f)
            FROM="--input-from "$OPTARG
        ;;
        t)
            TO="--input-to "$OPTARG
        ;;
        h)
            OUTPUT_HAPS=$OPTARG
        ;;
        o)
            OUTPUT_SAMPLE=$OPTARG
        ;;
        R)
            ROOT_DIR=$OPTARG
        ;;
        c)
            CHR=$OPTARG
        ;;
        l)
            LOG=$OPTARG
        ;;
        ?)
            echo "Options were not correctly sent" >&2
            exit 1
        ;;

    esac

done

# FIXME Get the hardcoded files.. yucky. For cluster will ovbiously need to change. again should be symlinked like all of our stuff. god knows why we didnt

REF_HAP="$ROOT_DIR/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_chr${CHR}_impute.hap"
MAP_FILE="$ROOT_DIR/tools/SOER1000genes/data/1kg/impute2/genetic_map_chr${CHR}_combined_b37.txt"
REF_LEGEND="$ROOT_DIR/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3_chr${CHR}_impute.legend"
REF_SAMPLE="$ROOT_DIR/tools/SOER1000genes/data/1kg/impute2/ALL_1000G_phase1integrated_v3.sample"

CHRX_TAG=""

if [ "$CHR" == "x" ] ; then

   CHRX_TAG="--chrX" 

fi

# Shape it or shape out!
shapeit --input-gen $INPUT_GEN $INPUT_SAMPLE --input-gen-threshold $THRESHOLD --input-map $MAP_FILE $FROM $TO $REF --output-max $OUTPUT_HAPS $OUTPUT_SAMPLE $CHRX_TAG

# Print log to stdout to be picked up by Galaxy
cat shapeit_*.log > $LOG

exit 0
