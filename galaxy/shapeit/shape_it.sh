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

while getopts "g:s:m:rf:t:h:o:" opt; do
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
        ?)
            echo "Options were not correctly sent" >&2
            exit 1
        ;;

    esac

done

# FIXME Get the hardcoded files.. yucky. For cluster will ovbiously need to change. again should be symlinked like all of our stuff. god knows why we didnt
REF_HAP="$ROOT_DIR/tools/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${CHR}_impute.hap"
MAP_FILE="$ROOT_DIR/tools/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${CHR}_impute.map"
REF_LEGEND="$ROOT_DIR/tools/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${CHR}_impute.legend"
REF_LEGEND="$ROOT_DIR/tools/data/1kg/impute2/ALL_1000G_phase1integrated_v3_impute/ALL_1000G_phase1integrated_v3_chr${CHR}_impute.sample"

# Shape it or shape out!
shapeit --input-gen $INPUT_GEN $INPUT_SAMPLE --input-thr $THRESHOLD --input-map $MAP_FILE $FROM $TO $REF --output-max $OUTPUT_HAPS $OUTPUT_SAMPLE

# Print log to stdout to be picked up by Galaxy
echo shapeit_*.log

exit 0
