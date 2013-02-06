"""

    Base Pair splitting for supported files in galaxy

    @Author James Boocock

"""

import logging

log = logging.getLogger(__name__)

class BasePair(object):


    def __init__(self, tool_wrapper):
        self.bases = {}
        self.bases['mb'] = 1000000
        self.bases['kb'] = 1000
        self.bases['b'] = 1
        self.tool_wrapper= tool_wrapper

    def create_directories(self):
        
        return directories

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
