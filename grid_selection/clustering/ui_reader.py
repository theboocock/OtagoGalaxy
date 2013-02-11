"""
    Reads the grid options from the galaxy ui

"""

import os
import sys
import logging
import threading


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
        self.job_options[job_id] = job_options

    def delete(self,job_id):
        del self.job_options[job_id]
        self.create_tasks.remove(job_id)
            

    def get_grid(self,job_id):


        return self.grids['local']
    
    def create_task(self, job_id):
        if job_id not in self.create_tasks:
                if job_id[job_id].get_parralelism().is_parralel():
                    self.create_tasks.append(job_id)
                    return True
        else:
            return False


    def is_parralel(self,job_id):
        #Read options from screen when job is run
        #return  False
        return True
       
    def get_splitting_options(self, job_id):
        return ['200000','bp']
    
    def shutdown( self):
        """Attempts to gracefully shutdown the monitor thread"""
        log.info("Sending shutdown to monitor thread")
        #self.monitor_jobs(self.STOP_SIGNAL())

        
