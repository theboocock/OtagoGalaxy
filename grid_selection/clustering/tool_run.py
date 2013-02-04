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

    def __init__(self,app, job_wrapper, grids, grid_runners):
        self.app = app
        self.job_wrapper = job_wrapper
        self.job_wrapper.prepare()
        self.command_line = job_wrapper.get_command_line()
        self.runner_url = self.get_runner_url()
        self.runner_name = self.get_runner_name()
        #Set to none for the local runner#  
        self.grid = grid
        log.debug(grid)
        self.datatypes = [] 
        # We are running on local or lwr if grid is none
        if runner_name in get_grid_runners(grid_runners): 
            log.debug(self.runner_name + " " + self.command_line)
            self.fake_galaxy_dir = grid.prepare_paths(job_wrapper.get_job().tool_id)
            grid.prepare_datatypes(job_wrapper)
        else:
            log.debug(self.runner_name + " " + self.command_line)
            log.debug("Skipping over interface user Selected local or lwr" )

    def get_grid_runners(self):
        runners = []
        for grid in self.grids:
            runners.append(grid.get_grid_runner())
        return runners

    def get_runner_url(self, job_wrapper):

        return "local:///"

    def get_runner_name(self, job_wrapper):
        runner_name = self.get_runner_url(job_wrapper).split(":",1)[0]
        return runner_name
        

