"""
    Galaxy __init__.py for Grid Selection module.
    
    Author James Boocock.
"""

import os
import sys
import logging

from elementtree import ElementTree

log = logging.getLogger(__name__)

class ClusteringInterface(object):
    """ Clustering Interface class contains everything the clustering inteface needs"""

    def __init__(self,app,job_runners,config_file):
        self.runners= []
        self.avaliable_runners= job_runners
        log.debug( job_runners)
        self.grids = {}

        self.parse(config_file):
        



    def init_grids(self,config_file):
        return 1

    def parse(self,root):

        #parse and create each individual grid object

class Grid(object):

    def __init__(self):
        self.blah = []



class Splitters(object):
    def __init__(self):
    
    def split(self):


class Merger(object):

    def merge(self):

