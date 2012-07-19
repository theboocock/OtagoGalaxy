#!/bin/bash
#
# first gzips input file (as galaxy currently doesn't allow gzipped files)
# and then runs treemix
# 
# $1 input file name
# $2 output_cov
# $3 output_covse
# $4 output_modelcov
# $5 output_treeout
# $6 output_vertices
# $7 output_edges
# $8 output_summary
# $9 output_png

INPUT=$1
OUT_1=$2
OUT_2=$3
OUT_3=$4
OUT_4=$5
OUT_5=$6
OUT_6=$7
OUT_7=$8
OUT_8=$9
OUT_9=$10

# have to zip files because currently galaxy wont store zips
gzip -c $1 > $1.gz

shift 10

COMMAND="treemix -i $INPUT.gz"

while getopts "r:l:m:v:e:" OPTION; do
    case $OPTION in
        r)
            ROOT_POS="$OPTARG"
            COMMAND="$COMMAND -root $ROOT_POS"
            ;;
        l)
            LD="$OPTARG"
            COMMAND="$COMMAND -k $LD"
            ;;
        m)
            MIGRATION="$OPTARG"
            COMMAND="$COMMAND -m $MIGRATION"
            ;;
        v)
            VERT_FILE="$OPTARG"
            COMMAND="$COMMAND -g $VERT_FILE"
            ;;
        e)
            EDGE_FILE="$OPTARG"
            COMMAND="$COMMAND $EDGE_FILE"
            ;;
        ?)
            echo "Invalid options: -$OPTION" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

COMMAND="$COMMAND -o galaxy_treemix"

$COMMAND > $OUT_7

# make R plot thing
Rscript ~/galaxy-dist/tools/SOER1000genes/galaxy/treemix/do_plots.R "`pwd`" 2> /dev/null

mv galaxy_tree.png $OUT_8

gunzip *.gz

mv -f *.cov $OUT_1
mv -f *.covse $OUT_2
mv -f *.modelcov $OUT_3
mv -f *.treeout $OUT_4
mv -f *.vertices $OUT_5
mv -f *.edges $OUT_6

exit 0
