"""

    parallelism.py performs all necessary setup for parrelelism 
    including each tool that exists

    @author James Boocock

"""

import os
import logging
#from bp import BasePairSplit
#from simple import SimpleSplit

log = logging.getLogger(__name__)

class Parallelism( object ):
    
    BASE_PAIR_SPLITS = ['bp','kb','mb']

    def __init__(self,splitters,mergers):
        """ Initalises the splitting methods"""
        self.splitters = splitters
        self.mergers = mergers

    def do_split(self, job_wrapper,splitting_method):
        parent_job = job_wrapper.get_job()
        working_dir = (os.path.abspath(job_wrapper.working_directory))
        fnames = job_wrapper.get_input_fnames()
        split_method = splitting_method[1]
        log.debug(fnames)
        if split_method in BASE_PAIR_SPLITS:
            log.debug("Trying to split by base pairs")
        elif split_method == 'simple': 
            log.debug("Trying to split simply")
        


    def do_merge(self, job_wrapper):
        return 1
