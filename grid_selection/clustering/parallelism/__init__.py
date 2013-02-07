""" 

    Parrellelism methods for galaxy

    @author James Boocock

"""




import os
import logging
#from bp import BasePairSplit
#from simple import SimpleSplit

from galaxy import model
import bp, simple
from sqlalchemy.sql.expression import and_, or_, select, func

log = logging.getLogger(__name__)
BASE_PAIR_SPLITS = ['bp','kb','mb']

class Parallelism( object ):
    

    def __init__(self,app,splitters,mergers,outputs, job_wrapper, outputs):
        """ Initalises the splitting methods"""
        self.splitters = splitters
        self.mergers = mergers
        self.bases = {}
        self.bases ['mb'] = 1000000
        self.bases ['kb'] = 1000
        self.bases ['bp']  =1
        self.base_pair_split = False
        self.simple_split = False
        self.app = app
        self.splitting_datasets= {}
        self.outputs = outputs
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
            #Get the intervals so we can calculate the number of directories#   
            log.debug("Trying to split by base pairs")
            #Need to set the splitting values across all the files
            #incase of empty split regions the header will be appended to the file
            # This should not effect vcf tools
            setter = dataset
            #create the maximum amount of task dirs
            task_dirs = splitter_modules[setter].get_directories(intervals,splitting_method, working_dir)
            log.debug(task_dirs)
            tasks = []
            #Set all the set all the global variables for each of the datasets.
            for data_set, splitter_class in splitter_modules.items():
                #set distance and no_divisions
                splitter_class.set_split_pairs(splitter_modules[setter].distance,splitter_modules[setter].no_divisions, splitter_modules[setter].max, splitter_modules[setter].min, splitter_modules[setter].bases_per_split)
                #try:
                splitter_class.do_split(data_set,task_dirs)
                #except AttributeError:
                #log_error ="The data_set '%s' does no define a method for splitting files" % str(data_set)
                #log.error(log_error)

            for dir in task_dirs:
                task= model.Task(parent_job,dir,None)
                tasks.append(task)
            return tasks

        elif split_method == 'simple': 
            # Simple split method NOT IMPLEMENTED #
            self.simple_split = True
            log.debug("Trying to split simply")
        

    #def get_input_formats(self, fnames):
    #    """ Query database to get the input format for the dataset """
    #    """ I know they are just stored as simple datasets with the ability to
    #     change dataformat based on each users history but for now merely querying the database
    #     and asking for the formats will really help the case we have """
    #    data_format_queury = self.sa_session.query(model.HistoryDatasetAssociation).enable_eagerloads(False) 
    #    #### DO DATABASE QUERY YOU CAN DO IT ####
    #    log.debug(data_format_queury)



    def do_merge(self, job_wrapper, task_wrappers):
        try:
            working_directory = job_wrapper.working_directory
            task_dirs = [os.path.join(working_directory, x) for x in os.listdir(working_directory) if x.startswith('task_')]
            assert task_dirs, "There should be atleast one sub-task"
            parent_job = job_wrapper.get_job()
            #Get output dataset.
            outputs_datasets = parent_job.output_datasets
            #For now matching format with output. So vcf is merged using vcf merger.
            #Takes all the files and does the merge

            #Matches datasets by format for now so all outputs with the same fname as the original
            #input are concatenated into a new file.
            #skip every thing else unless it matches
            outputs = job_wrapper.g()
            for output in outputs:
                log.debug(output.dataset.ext)
            task_dirs.sort(key = lambda x: int(x.split('task_')[-1]))
            for outputs in self.outputs:
                log.debug(output_names)               
                outputs = [os.path.join(dir, base_output_name) for dir in task_dirs]
                output_files = [f for f in output_files if os.path.exists(f)
                if output_files:
                    log.debug("files %s " % output_files)
                            





        
       return 1 
