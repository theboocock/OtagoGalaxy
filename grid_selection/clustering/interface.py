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


from elementtree import ElementTree

log = logging.getLogger(__name__)


class ClusteringInterface(object):
    """ Clustering Interface class contains everything the clustering inteface needs"""

    def __init__(self,app,job_runners,config_file):
        self.app =app
        self.runners= []
        self.avaliable_runners= job_runners
        log.debug( job_runners)
        self.grids_by_id = {}
        #HARDCODED DEFAULT FOR TESTING
        config_file = ('/home/jamesboocock/OtagoGalaxy/grid_selection/conf/grid_conf.xml')
        try:
            self.init_grids(config_file)
        except:
            log.exception("Error loading grids specifed in the config file {0}".format(config_file))

    def init_grids(self,config_file):
        """ Initalise all the grids specfied in the grid config file"""
        tree=util.parse_xml(config_file)
        root=tree.getroot()
        for _, elem in enumerate(root):
            if elem.tag == "grid":
                grid = Grid(elem,self.app)
                self.grids_by_id[grid.id] = grid

    def print_grids(self):
        for grid in self.grids_by_id:
            print grid.name





