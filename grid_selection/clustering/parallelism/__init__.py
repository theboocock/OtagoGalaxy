""" 

    Parrellelism methods for galaxy

    @author James Boocock

"""




import os
import logging
#from bp import BasePairSplit
#from simple import SimpleSplit
import bp, simple
from sqlalchemy.sql.expression import and_, or_, select, func

log = logging.getLogger(__name__)
BASE_PAIR_SPLITS = ['bp','kb','mb']

class Parallelism( object ):
    

    def __init__(self,app,splitters,mergers, job_wrapper):
        """ Initalises the splitting methods"""
        self.splitters = splitters
        self.mergers = mergers
        self.base_pair_split = False
        self.simple_split = False
        self.app = app
        self.sa_session = app.model.context
        self.job_wrapper = job_wrapper
        self.input_fnames_formats = get_input_formats(job_wrapper.get_input_fnames())

    def do_split(self, job_wrapper,splitting_method):
        """Does the splitting for the job"""
        parent_job = job_wrapper.get_job()
        working_dir = (os.path.abspath(job_wrapper.working_directory))
        fnames = job_wrapper.get_input_fnames()
        split_method = splitting_method[1]
        input_formats = get_input_formats()
        if split_method in BASE_PAIR_SPLITS:
            self.base_pair_split = True
            log.debug("Trying to split by base pairs")
        elif split_method == 'simple': 
            self.simple_split = True
            log.debug("Trying to split simply")
        

    def get_input_formats(self, fnames):
        """ Query database to get the input format for the dataset """
        """ I know they are just stored as simple datasets with the ability to
         change dataformat based on each users history but for now merely querying the database
         and asking for the formats will really help the case we have """
         data_format_queury = self.sa_session.query(model.HistoryDatasetAssociation).enable_eagerloads(False) 
         #### DO DATABASE QUERY YOU CAN DO IT ####
         log.debug(data_format_queury)

    def do_merge(self, job_wrapper):
        return 1

