"""
    Reads the grid options from the galaxy ui

"""

import os
import sys
import logging
import threading
import ConfigParser
from job_options import JobOptions
from job_options import ParralelismOptions

log = logging.getLogger(__name__)

class UiReader(object):

    STOP_SIGNAL= object()
    def __init__(self,app,grids,parralelism_options):
        """Constantly setup tool_id """
        self.app=app
        self.grids=grids
        self.monitored_jobs=[]
        log.debug(parralelism_options)
        Config = ConfigParser.ConfigParser()
        Config.read(parralelism_options)
#        self.monitor_thread =threading.Thread ( name="UiReader.monitor_thread" target=self.__monitor()
        self.ui_objects = {}
        self.create_tasks = []
        self.job_options = {}
 #       self.monitor_thread.start()
        for item in Config.sections(): 
            print(item)
            incoming ={}
            incoming['grid']=Config.get(item,'grid')
            incoming[incoming['grid'] + "+" + 'parralel_type']=Config.get(item,'parralel_type')
            incoming[incoming['grid'] + "+" + 'parralel_options']=Config.get(item,'parralel_string')
            print incoming
            self.put(item.split(':')[1],incoming)
            

    def put(self,tool_id, job_options):
        log.debug(tool_id + "   job _options: " +  str(job_options))
        self.job_options[tool_id] = JobOptions(self.app,job_options)


    def delete(self,tool_id):
        del self.job_options[tool_id]
        self.create_tasks.remove(tool_id)
            

    def get_grid(self,tool_id):
        log.debug(self.grids)
        log.debug(self.job_options)
        if tool_id == 'upload1':
            return self.grids['local']
        if tool_id not in self.job_options:
            return self.grids['local']
        else:
            return self.grids[self.job_options[tool_id].get_grid()]
      
    
    def create_task(self, tool_id):
        #self.job_options[tool_id]= JobOptions(self.app, self.get_splitting_options(1),None,None)
        if tool_id == 'upload1':
            return False
        if tool_id not in self.create_tasks:
                if self.is_parralel(tool_id):
                    self.create_tasks.append(tool_id)
                    return True
                else:
                    return False
        else:
            return False


    def is_parralel(self,tool_id):
        #Read options from screen when job is run
        if tool_id == "upload1":
            return  False
        if tool_id not in self.job_options:
            return False
        else:
            return self.job_options[tool_id].get_parralelism().is_parralel()
       
    def get_splitting_options(self, tool_id):
        splitting_options = []
        log.debug(tool_id)
        splitting_options.append(self.job_options[tool_id].get_parralelism().get_splitting_number())
        splitting_options.append(self.job_options[tool_id].get_parralelism().get_splitting_type())
        return splitting_options
    
    def shutdown( self):
        """Attempts to gracefully shutdown the monitor thread"""
        log.info("Sending shutdown to monitor thread")
        #self.monitor_jobs(self.STOP_SIGNAL())

        
