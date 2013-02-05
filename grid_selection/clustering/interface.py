"""
    Clustering Interface For Galaxy
    Date: January 2013
    Author: James Boocock
"""

#Python Imports
import os
import sys
import logging

#Clustering Module Imports
import util
from grid import Grid
from tool_run import ToolRun
from ui_reader import UiReader
from elementtree import ElementTree

log = logging.getLogger(__name__)
DEFAULT_CLUSTERING_FAIL_MESSAGE= " Unable to run job due to the misconfiguration of the clustering inteface "

class ClusteringInterface(object):
    """ Clustering Interface class contains everything the clustering inteface needs"""

    def __init__(self,app,job_runners,config_file):
        self.app =app
        self.avaliable_runners= job_runners
        log.debug( job_runners)
        self.grids_by_id = {}
        
        #HARDCODED DEFAULT FOR TESTING
        config_file = ('/home/jamesboocock/OtagoGalaxy/grid_selection/conf/grid_conf.xml')
        try:
            self.init_grids(config_file)
        except:
            log.exception("Error loading grids specifed in the config file {0}".format(config_file))
        log.debug(self.generate_avaliable_grids())
#       Do some ui reading
        self.ui_reader = UiReader(self.app,self.grids_by_id)

    def init_grids(self,config_file):
        """ Initalise all the grids specfied in the grid config file"""
        tree=util.parse_xml(config_file)
        root=tree.getroot()
        for _, elem in enumerate(root):
            if elem.tag == "grid":
                grid = Grid(elem,self.app,self.avaliable_runners)
                self.grids_by_id[grid.id] = grid
        
    def get_grid(self, job_wrapper):
        return self.grids_by_id['nesi0']

    def put(self, job_wrapper):
        try:
            tool_run = ToolRun(self.app, job_wrapper,self.grids_by_id,self.ui_reader) 
            runner_name = tool_run.get_runner_name()
            # If the grid is local or lwr we wont have a grid
            # Object so the tool should continue to
            # Run as if nothing has changed.
            if runner_name is "local" or runner_name is "lwr":
                grid = None
            else:
                grid = self.get_grid(job_wrapper)
            self.avaliable_runners[runner_name].put(job_wrapper)
        except KeyError:
            log.exception("put(): (%s) Invalid Job Runner: %s" %( job_wrapper.job_id, runner_name))
            job_wrapper.fail(DEFAULT_CLUSTERING_FAIL_MESSAGE)

   
    def stop(self, job):
        return 1

    def recover(self, job, job_wrapper):
        return 1


    def print_grids(self):
        """ Prints out all the avaliable grids """
        for grid in self.grids_by_id:
            print grid.name
    
    def generate_avaliable_grids(self):
        """ Gets all the avaliabe grids """
        grid_names=[]
        for grid in self.grids_by_id:
            grid_names.append(grid)
        return grid_names

    def get_ui_reader(self):
        return self.ui_reader


