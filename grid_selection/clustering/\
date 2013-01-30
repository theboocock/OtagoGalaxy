"""
    Clustering Interface For Galaxy
    Date: January 2013
    Author: James Boocock
"""

import os
import sys
import logging

#Import clustering modules
import grid


from elementtree import ElementTree, ElementInclude

log = logging.getLogger(__name__)


class ClusteringInterface(object):
    """ Clustering Interface class contains everything the clustering inteface needs"""

    def __init__(self,app,job_runners,config_file):
        self.app =app
        self.runners= []
        self.avaliable_runners= job_runners
        log.debug( job_runners)
        self.grids_by_name = {}
        #HARDCODED DEFAULT FOR TESTING
        config_file = ('/home/jamesboocock/OtagoGalaxy/grid_selection/conf/grid_conf.xml')
        try:
            self.init_grids(config_file)
        except:
            log.exception("Error loading grids specifed in the config file {0}".format(config_file))

    def init_grids(self,config_file):
        """ Initalise all the grids specfied in the grid config file"""
        tree=self.parse_xml(config_file)
        root=tree.getroot()
        for _, elem in enumerate(root):
            if elem.tag == "grid":
                grid = Grid(elem,self.app)

    def print_grids(self):
        print self.grid_by_name

    def return_runner_from_url(self,runner_url):
        """Returns the galaxy runner from a galaxy runner url"""
        return 1
    def parse_xml(self,fname):
        """Parse XML file using elemenTree"""
        tree=ElementTree.parse(fname)
        root=tree.getroot()
        ElementInclude.include(root)
        return tree

    #parse and create each individual grid object

