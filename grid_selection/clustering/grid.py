"""
    Grid Class Encapsulates all the information for a galaxy grid

    Date: January 2013
    Author: James Boocock

"""

import os
import sys
import logging

from elementtree import ElementTree

class Grid(object):
    """ Class that encapsulates every individual grid object and contains all
        the information that is needed for the clustering interface """
    def __init__(self,elem,app):
        self.app = ""
        self.name = ""
        self.runner_url= ""
        self.queues={}
        self.galaxy_options={}
        # something like self.runtime to encapsulate information about galaxy options
        # Have not decided what to do for each.

        #Tool mapping from galaxy tool id to with the rules for the grid
        self.grid_tools={}
        self.parse(elem)
