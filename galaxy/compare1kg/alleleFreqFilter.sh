#!/bin/bash
#
#*** *** ** DEPRECEATED --- NO LONGER USERD **** ***** ****
#
# Filters VCF file by allele frequency 
# removes lines that do not contain AF column
#
# $1 file
# $2 threshold below which to throw away line
# $3 more or less
# $4 snps / indels / all
# $5 database
# $6 population (if database == evs)
while read line
do
    if [ "$4" != "all" ] ;then
        line=`echo $line | grep -i "$4"`
        if [ "$line" == "" ] ;then
            continue
        fi
    fi

    # get the info column
    INFO_COLUMN=`echo $line | awk '{if($8 ~ /AF=/){print $8}}'`
    if [ "$INFO_COLUMN" != "" ] ;then

        #get the af=freq pair
        AF_PAIR=`echo $INFO_COLUMN | awk -F[\;] '{ for (i=1;i<= NF;i++) {
                                                            if ($i ~/AF=/)
                                                                {print $i}
                                                            }
                                                }'`

        # print the line if is more or less than threshold and snp/indel
        if [ "$AF_PAIR" != "" ]; then

            if [ "$5" == "1kg" ] ;then 

                if [ "$3" == "more" ] ;then
                    AF_NUMBER=`echo $AF_PAIR | awk -v AF=$2 -F[\=] '{if($2 >= AF){
                                                                        print $0
                                                                    }}'`
                fi
                if [ "$3" == "less" ] ;then
                    AF_NUMBER=`echo $AF_PAIR | awk -v AF=$2 -F[\=] '{if($2 <= AF){
                                                                        print $0
                                                                    }}'`
                fi

            else

                if [ "$3" == "more" ] ;then
                    TRIP=`echo $AF_PAIR | awk -F[\=] '{print $2}'`
                    AF_NUMBER=`echo $AF_PAIR | awk -v AF=$2 -v POP=$6 -F[,] '{if($POP >= AF){
                                                                        print $POP
                                                                    }}'`
                fi
                if [ "$3" == "less" ] ;then
                    TRIP=`echo $AF_PAIR | awk -F[\=] '{print $2}'`
                    POP=$6
                    AF_NUMBER=`echo $AF_PAIR | awk -v AF=$2 -v POP=$6 -F[,] '{if($POP <= AF){
                                                                        print $POP
                                                                    }}'`
                fi

            fi

            if [ "$AF_NUMBER" != "" ];then
                    echo "$line"
            fi
        fi
    fi

done < $1

