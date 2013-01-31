"""
    Grid Tool is a class that represents
    everything needed for a tool to run on a galaxy grid

    Author James Boocock
"""

import os
import sys
import logging

from elementtree import ElementTree

log = logging.getLogger(__name__)

class GridTool(object):

    def __init__(self,elem,app):
        self.app = app
        self.id = ""
        self.paths= {}
        self.splitter= None
        self.merger = None
        self.parse(self, elem)
    
    def parse(self, elem):
       return 1 

