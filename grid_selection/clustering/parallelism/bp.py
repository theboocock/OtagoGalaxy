"""

    Base Pair splitting for supported files in galaxy
    Currently vcf is supported
    looking at impute2 +  shapeit data
    @Author James Boocock

"""

import logging
import math
import os
import time
#For the creation of the tasks
from galaxy import model

log = logging.getLogger(__name__)

class BasePair(object):


    def __init__(self, tool_wrapper):
        self.bases = {}
        self.bases['mb'] = 1000000
        self.bases['kb'] = 1000
        self.bases['bp'] = 1
        self.tool_wrapper= tool_wrapper
        self.no_divisions = 0
        self.distance = 0
        self.min = 0
        self.max = 0
        self.bases_per_split = 0

    def get_directories(self,intervals,splitting_method,working_dir):
        self.min = int(intervals[0].split('-')[0])
        self.max = int(intervals[0].split('-')[1])
        for interval in intervals:
            if int(interval.split('-')[0]) < self.min:
                self.min = int(interval.split('-')[0])
            if interval.split('-')[1] > self.max:
                self.max = int(interval.split('-')[1])
        self.distance=int(self.max) - int(self.min)
        #Calculates the number of Directories required
        #log.debug(self.bases)
        #log.debug(self.bases[splitting_method[1]])
        self.no_divisions= int(math.ceil(self.distance / (float(self.bases[splitting_method[1]]) * float(splitting_method[0]))))
        self.bases_per_split = int(splitting_method[0]) * int(self.bases[splitting_method[1]])
        #log.debug(self.no_divisions)
        #log.debug(self.distance)
        task_dirs = []
        for i in range(0,self.no_divisions):
            dir=os.path.join(working_dir, 'task_%d' %i)
            if not os.path.exists(dir):
                os.makedirs(dir)
            task_dirs.append(dir)
            
        log.debug("get_directories created %d folders" % i)
        return task_dirs

    def set_split_pairs(self, distance, no_divisions, max, min,bases_per_split):
        self.distance = distance
        self.no_divisions = no_divisions
        self.max = max
        self.min = min
        self.bases_per_split = bases_per_split
            


class Vcf(BasePair):

    def __init__(self, tool_wrapper):
        BasePair.__init__(self, tool_wrapper)

    """Performs the splitting on a basepair region"""
    def do_split(self, dataset, task_dirs):
        #Get the start of the region
        start = self.min
        max_region = self.min + self.bases_per_split
        log.debug(str(self.min)  + "     " + str(self.bases_per_split))
        #Get the file_name
        fname = self.tool_wrapper.get_input_dataset_fnames(dataset)
        with open(fname[0], 'r') as f:
            try:
                header = ""
                line = f.readline()
                while ("#" in line):
                    header += line
                    line= f.readline()
                for value in task_dirs:
                    part_dir = value
                    part_path= os.path.join(part_dir, os.path.basename(fname[0]))
                    part_file = open(part_path, 'w')
                    check_pos = line.split()
                    check_pos = int(check_pos[1])
                    part_file.write(header)
                    #log.debug("max region: " + str(max_region))
                    #log.debug("check_pos: " + str(check_pos))
                    while (check_pos < max_region):
                        part_file.write(line)
                        line = f.readline()
                        # Should break on the final iteration
                        if not line:
                            break
                        check_pos = line.split()
                        check_pos = int(check_pos[1])
                    max_region = max_region  + self.bases_per_split
                    if not line:
                        break
                    if part_file is not None:
                        part_file.close()
            except Exception, e:
                    log.error("Unable to split files: %s" % str(e))
                    if part_file is not None:
                        part_file.close()

    def do_merge(self, dataset, task_dirs):
        header = ''
        fname = self.tool_wrapper.get_input_dataset_fnames(dataset.dataset)
        read_header = True
        base_name=os.path.basename(fname[0])
        with open(fname[0],'w') as out:
            for task_dir in task_dirs:
                list_dir = os.listdir(task_dir)
                for files in list_dir:
                    if files == base_name:
                        with open(os.path.join(task_dir,files), 'r') as part_file:
                            for line in part_file:
                                if(read_header == True and "#" in line):
                                    out.write(line)
                                elif not "#" in line:
                                    out.write(line)
                read_header = True
                
    def get_interval(self, hist_dataset):
        interval=""
        fname = self.job_wrapper.get_input_dataset_fnames(hist_dataset)
        fname=fname[0]
        #We can do this because we know a vcf file is not a composite datatype
        with open(fname, 'r') as vcf:
            line = vcf.readline()
            while("#" in line):
                line=vcf.readline()
            i=0 
            for line in vcf:
                if (i == 0):
                    line=line.split()
                    interval += line[1]
                i = i + 1

            interval+="-"
            interval+=line.split()[1]
        log.debug(interval)
        return interval

class ShapeIt(BasePair):
    def __init__(self, tool_wrapper):
        BasePair.__init__(self, tool_wrapper)
    
    def get_interval(self,hist_dataset):
        #Get the intervals from data that has been pre-phased by
        # shiapeit
        interval=""
        log.debug(hist_dataset.dataset)
        dataset=hist_dataset
        log.debug(dataset)
        extra_files=dataset.extra_files_path
        log.debug(extra_files)
        base_name=dataset.metadata.base_name
   # def do_merge(self, dataset,task_dirs):
        #Will never get used for now

  #  def do_split(self, dataset, task_dirs):
        

#class GTool(BasePair)

class Impute2(BasePair):
    def __init__(self, tool_wrapper):
        BasePair.__init__(self, tool_wrapper)
    
   # def get_intervals(self,fname):
        #dont need this yet

    #def do_merge(self, dataset,task_dirs):
        # Create the merge function

    #def do_split(self, dataset, task_dirs):
        #skip this
