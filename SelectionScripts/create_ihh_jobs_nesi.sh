#!/bin/bash

#
# $1 large_input_file
# $2 window
# $3 overlap
# $4 parralel cores
# $5 Chromosome
#
# The overlap is the overlap for each chunk in this case 10* the overlap for
# the job run
# 
# 

help(){
cat << EOF
	create_ihh_jobs_nesi.sh 
        arguments are a follows
	1 = input_haps_file
	2 = Window size
	3 = overlap between all the chunks
	4 = parrallel cores
	5 = Chromosome 
    6 = population
    7 = MAF filter
EOF
}

if [ "$1" == "" ] ; then
	help
	exit 1
fi

bigWindow=`echo "(${2}-${3}) * (${4}) + ${3}" | bc`
echo $bigWindow
max_line=`tail -1 $1 | awk '{ print $3 }'`
let "limit = 30000 * 1024"

noFolders=`echo "(${max_line}+${3})/(${bigWindow}-${3}) + 1" | bc`
echo $noFolders 
python prepare_files_aa.py $1 $bigWindow $3 $6
for i in $(eval echo "{1..${noFolders}}") ; do
     let "offset = ${i} * 10"
     offset=`echo "${offset} - 9" | bc`
     echo "${i}" >> folderlist
     echo "Processing $i in $working_dir"
     echo "#@ shell = /bin/bash
     #@ environment = COPY_ALL
     #@ job_name = ihs_CEU_${i}
     #@ job_type = serial
     #@ group = nesi
     #@ class = default
     #@ notification = never
     #@ wall_clock_limit = 107:59:00
     #@ resources = ConsumableMemory(30gb) ConsumableVirtualMemory(30gb)
     #@ output = ${i}/\$(jobid).out
     #@ error = ${i}/\$(jobid).err
     #@ parallel_threads =${4} 
     #@ notification = complete
     #@ queue
 		 
     module load R/3.0.1
     # ulimit sets memory constraints for jobs running on single nodes (to prevent the job
     # from consuming too much memory).
     # The first argument is in KB and should equal ConsumableMemory.
     ulimit -v ${limit} -m ${limit}
     mkdir $i
     # Call R with the input file as a command line argument
     Rscript multicore_iHH.R $6 ${6}${i}.phaps $5 $2 $3 $4 $i $offset ${7}
	" > ${i}.job
     sync
     llsubmit ${i}.job
 
     #remove the temp file
     #rm ${i}.job	
done

