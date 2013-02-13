"""
    Tool run for galaxy clustering interfacte
    Date: January 2013
    Author: James Boocock
"""

""" This class prepares everything related to a tool run in the galaxy clustering interface """
import os
import sys
import logging

import util

log =logging.getLogger(__name__)

class ToolRun(object):
    """ Tool run class contains functions to perform the setup to run each individual tool"""

    def __init__(self,app, job_wrapper, grids,ui_reader):
        self.app = app
        self.ui_reader = ui_reader
        self.job_wrapper = job_wrapper
        self.job_wrapper.prepare()
        self.command_line = job_wrapper.get_command_line()
        self.job_id = self.job_wrapper.job_id
        #Set to none for the local runner#  
        self.grid_to_run_on = self.ui_reader.get_grid(self.job_id)
        log.debug("BLAH")
        self.grids = grids
        log.debug(grids)
        self.datatypes = [] 
        # need to get the grid from the ui that the user has selected #
        # We are running on local or lwr if grid is none
        job = job_wrapper.get_job()
        #Do parrarelism stuff so set the runner to tasks.

        #Check to see whether the user defined any split options
        #Check to make sure we have enabled tasked jobs
        if self.ui_reader.is_parralel(self.job_id) and not self.app.config.use_tasked_jobs:
            raise Exception, "Use tasked jobs needs to be set to true in your universe config to use parralelism options"
        result = self.ui_reader.create_task(self.job_id) 
        if result:
            """ Do all the parralelism here """
            log.debug("Job Running in parralel")
            #Requires tasks be enabled in galaxy otherwise the job dispatcher wont start#
            self.runner_name="tasks"
             
            # this will create all the tasks needed to run the galaxy job #
            # setting the runner to tasks the tasks will be run from galaxy and come back through here to get 
            # sent to the runner each of the tasks where set to go to #
            # tasks are created so galaxy can unset parralelism and all future tasks will be sent to what
            # they are meant to be set to 
             
            #unset parrellel after
        #Final setup of job sends it to the task runner.
        elif self.grid_to_run_on is "local" or self.grid_to_run_on is "lwr":
            #Do local and lwr preparation here # 

            log.debug("BLAH")
            #in this case the runner name and the job runner name are the same thing #
            # This means grid id cannot be local or lwr #
            self.runner_name =  self.grid_to_run_on
            log.debug(self.runner_name + " " + self.command_line)
            log.debug("Skipping over interface user Selecter local or lwr runner")
        else:
            try:
                self.runner_name= self.grid_to_run_on.get_grid_runner() 
            #Do grid preparation here#
                log.debug(self.grid_to_run_on)
                log.debug(self.runner_name + " " + self.command_line)
                #self.fake_galaxy_dir = grid.prepare_paths(job_wrapper.get_job().tool_id)
                #grid.prepare_datatypes(job_wrapper)
            except:
                log.debug("Could not get a grid runner for grid: " + str(self.grid_to_run_on))
    

    def get_grid_runners(self):
        runners = []
        for grid in self.grids:
            runners.append(self.grids[grid].get_grid_runner())
        return runners
    def get_grids(self):
        for grid in self.grids:
            return grid
    def get_grid_from_ui(self):
        """Get the selected grid to run the job from the ui for this job"""
        
        #for grid in self.grids:
         #   return self.grids[grid]
        return "local"

    def get_tool_options(self):
        return 1


    """ Accessors """

    def get_runner_name(self):
        return self.runner_name
