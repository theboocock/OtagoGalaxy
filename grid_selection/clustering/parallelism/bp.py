"""

    Base Pair splitting for supported files in galaxy
    Currently vcf is supported
    looking at impute2 +  shapeit data
    @Author James Boocock

"""

import logging
import math
import os

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

    def get_directories(self,intervals,splitting_method,working_dir):
        min = intervals[0].split('-')[0]
        max = intervals[0].split('-')[1]
        for interval in intervals:
            if interval.split('-')[0] < min:
                min = interval.split('-')[0]
            if interval.split('-')[1] > max:
                max = interval.split('-')[1]
        log.debug("max: " + max + " min: " + min)
        self.distance=int(max) - int(min)
        #Calculates the number of Directories required
        log.debug(self.bases)
        log.debug(self.distance)
        self.no_divisions= int(math.ceil(self.distance / (float(self.bases[splitting_method[1]]) * float(splitting_method[0]))))
        log.debug(self.no_divisions)
        log.debug(self.distance)
        task_dirs = []
        for i in range(0,self.no_divisions):
            dir=os.path.join(working_dir, 'task_%d' %i)
            if not os.path.exists(dir):
                os.makedirs(dir)
            task_dirs.append(dir)
            
        log.debug("get_directories created %d folders" % i)
        return task_dirs

    def set_split_pairs(self, distance, no_divisions):
        self.distance = distance
        self.no_divisions = no_divisions
            


class Vcf(BasePair):

    def __init__(self, tool_wrapper):
        BasePair.__init__(self, tool_wrapper)

    """Performs the splitting on a basepair region"""
    def do_split(self, start, end):
        
        return 1

    def do_merge(self, start, end):
        return 1
    def get_interval(self, fname):
        interval=""
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
        return interval

#class Shapeit(BasePair):
