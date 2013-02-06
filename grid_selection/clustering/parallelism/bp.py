"""

    Base Pair splitting for supported files in galaxy

    @Author James Boocock

"""



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
    def get_intervals(self, fname):
        return 1


#class Shapeit(BasePair):
