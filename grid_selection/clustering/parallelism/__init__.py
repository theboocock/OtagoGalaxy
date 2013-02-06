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
        self.bases = {}
        self.bases ['mb'] = 1000000
        self.bases ['kb'] = 1000
        self.bases ['b']  =1
        self.base_pair_split = False
        self.simple_split = False
        self.app = app
        self.splitting_datasets= {}
        self.sa_session = app.model.context
        self.job_wrapper = job_wrapper
        #self.input_fnames_formats = get_input_formats(job_wrapper.get_input_fnames())

    def do_split(self, job_wrapper,splitting_method):
        """Does the splitting for the job"""
        parent_job = job_wrapper.get_job()
        working_dir = (os.path.abspath(job_wrapper.working_directory))
        fnames = job_wrapper.get_input_fnames()
        split_method = splitting_method[1]
        #TODO DEAL WITH NEW DATASETS THAT ARE NOT TO BE SPLIT

        #Create a list of splitting modules if there are multiple input formats 
        # it should be fine also shared datasets will also work
        # but not right now
        splitter_modules = {}
        #TODO
        #input_formats = get_input_formats()
        for input in parent_job.input_datasets:
            ext = input.dataset.ext
            self.splitting_datasets[input.dataset] = self.splitters[ext]
        log.debug(self.splitting_datasets)
        if split_method in BASE_PAIR_SPLITS:
            #TODO MAKE THIS A FUNCTION #
            self.base_pair_split = True
            intervals = []
            for dataset, splitter in self.splitting_datasets.items():
                log.debug(dataset)
                log.debug(splitter)
                splitter_class = getattr(bp,splitter)
                splitter_modules[dataset] = splitter_class(self.job_wrapper)
                fname = self.job_wrapper.get_input_dataset_fnames(dataset)
                intervals.append(splitter_modules[dataset].get_interval(fname[0]))
               
            min = intervals.split('-')[0]
            max = intervals.split('-')[1]
            for interval in intervals:
                if interval.split('-')[0] < min:
                    min = interval.split('-')[0]
                if interval.split('-')[1] > max:
                    max = interval.split('-')[1]
            distance=max - min
            no_divisions=distance / self.bases[split_method]
            log.debug(no_divisions)
            log.debug(distance)

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
