"""
    Reads the grid options from the galaxy ui

"""

import os
import sys
import logging
import threading
from job_options import JobOptions
from job_options import ParralelismOptions

log = logging.getLogger(__name__)

class UiReader(object):

    STOP_SIGNAL= object()
    def __init__(self,app,grids):
        """Constantly setup job_id """
        self.app=app
        self.grids=grids
        self.monitored_jobs=[]
#        self.monitor_thread =threading.Thread ( name="UiReader.monitor_thread" target=self.__monitor()
 #       self.monitor_thread.start() 
        self.ui_objects = {}
        self.create_tasks = []
        self.job_options = {}

    def put(self,job_id, job_options):
        log.debug(job_options)
        self.job_options[job_id] = JobOptions(self.app,job_options)

    def delete(self,job_id):
        del self.job_options[job_id]
        self.create_tasks.remove(job_id)
            

    def get_grid(self,job_id):
        return self.grids[self.job_options[job_id].get_grid()]
      
    
    def create_task(self, job_id):
        log.debug(str(job_id) + "  = Job id "  + " Parralelism = " )
        #self.job_options[job_id]= JobOptions(self.app, self.get_splitting_options(1),None,None)
        if job_id not in self.create_tasks:
                if self.job_options[job_id].get_parralelism().is_parralel():
                    self.create_tasks.append(job_id)
                    return True
        else:
            return False


    def is_parralel(self,job_id):
        #Read options from screen when job is run
        #return  False
        return self.job_options[job_id].get_grid()
       
    def get_splitting_options(self, job_id):
        splitting_options = []
        splitting_options.append(self.job_options[job_id].get_parralelism().get_splitting_number())
        splitting_options.append(self.job_options[job_id].get_parralelism().get_splitting_type())
        return splitting_options
    
    def shutdown( self):
        """Attempts to gracefully shutdown the monitor thread"""
        log.info("Sending shutdown to monitor thread")
        #self.monitor_jobs(self.STOP_SIGNAL())

        
