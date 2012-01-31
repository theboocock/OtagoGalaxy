#!/bin/bash
#
# region effect filter.
#
# Filters a VCF file which has had genomic annotations from snpEff added.
#
# @Author JAmes Boocock
#
# $1 input_vcf 
# $2 impact filters
# $3 effect filters
# $4 option used

SNPSIFT_EXPR=''
SNPEFF_IMPACT="${2}," 
SNPEFF_EFFECT="${3},"
COUNT=0


while echo $SNPEFF_IMPACT | grep \, &> /dev/null
do

    IMPACT=${SNPEFF_IMPACT%%\,*}
    #Remove the item from the list.
    SNPEFF_IMPACT=${SNPEFF_IMPACT#*\,}
    #Add the item to the snpSift expression string
    if [ $4 == "snpeff" ]; then
    if [ "$COUNT" == "0" ]; then

       SNPSIFT_EXPR="${SNPSIFT_EXPR}!( EFF[*].IMPACT = '${IMPACT}' )"
    else
       SNPSIFT_EXPR="${SNPSIFT_EXPR} & !( EFF[*].IMPACT = '${IMPACT}' )"
    fi

    elif [ "$4" == "genomic2" ] ; then

    if [ "$COUNT" == "0" ]; then
       SNPSIFT_EXPR="${SNPSIFT_EXPR}!( "resource.EFF[*]".IMPACT = '${IMPACT}' )"
    else
       SNPSIFT_EXPR="${SNPSIFT_EXPR} & !( "resource.EFF[*]".IMPACT = '${IMPACT}' )"
    fi
    else 
    if [ "$COUNT" == "0" ] ; then 
    SNPSIFT_EXPR="${SNPSIFT_EXPR}!((na SNPEFF_IMPACT) |(SNPEFF_IMPACT = '${IMPACT}') )"
    else
    SNPSIFT_EXPR="${SNPSIFT_EXPR} & !((na SNPEFF_IMPACT) | ( SNPEFF_IMPACT = '${IMPACT}') )"
    fi
    fi
    COUNT=`expr $COUNT + 1`
done

while echo $SNPEFF_EFFECT | grep \, &> /dev/null
do
    #Grab an item from the list
    EFFECT=${SNPEFF_EFFECT%%\,*}
    #Remove the item from the list
    SNPEFF_EFFECT=${SNPEFF_EFFECT#*\,}
    #Add the item to the snpSift expression string
    if [ "$4" == "snpeff" ] ; then
    if [ "$COUNT" == "0" ] ; then
    SNPSIFT_EXPR="${SNPSIFT_EXPR} !( EFF[*].EFFECT = '${EFFECT}' )"
    else
    SNPSIFT_EXPR="${SNPSIFT_EXPR} & !( EFF[*].EFFECT = '${EFFECT}' )"    
    fi
    elif [ "$4" == "genomic2" ] ; then

    if [ "$COUNT" == "0" ]; then
       SNPSIFT_EXPR="${SNPSIFT_EXPR}!( resource.EFF[*].EFFECT = '${IMPACT}' )"
    else
       SNPSIFT_EXPR="${SNPSIFT_EXPR} & !( resource.EFF[*].EFFECT = '${IMPACT}' )"
    fi
    else
    if [ "$COUNT" == "0" ] ; then
    SNPSIFT_EXPR="${SNPSIFT_EXPR} !( (na SNPEFF_EFFECT) | (SNPEFF_EFFECT = '${EFFECT}') )"
    else
    SNPSIFT_EXPR="${SNPSIFT_EXPR} & !( (na SNPEFF_EFFECT) | (SNPEFF_EFFECT = '${EFFECT}') )"
    fi
    fi 
    COUNT=`expr $COUNT + 1`
done
cat $1 | java -jar ~/galaxy-dist/tool-data/shared/jars/snpEff/SnpSift.jar filter "$SNPSIFT_EXPR"





