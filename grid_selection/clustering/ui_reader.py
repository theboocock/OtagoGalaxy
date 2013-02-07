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
        

            

    def get_grid(self,job_id):
        return self.grids['local']

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

        
