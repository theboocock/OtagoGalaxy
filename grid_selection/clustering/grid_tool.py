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

class InputDatatype(object):
    """ Class that encapsulates every individual input object and contains
        all the information that is needed for the clustering interface """

    def __init__(self, elem, app):
        self.app = app
        self.splitter= None
        self.merger = None
        self.format = ""
        self.output_name = ""
        self.parse(elem)
    
    def parse(self, elem):
        self.format=elem.get("format")
        if not self.format:
            raise Exception, "Mising format tag in datatype tag"
        self.splitter=elem.get("splitter")
        if not self.splitter:
            raise Exception, "Missing splitter tag in datatype tag"
        self.merger=elem.get("merger")
        if not self.merger:
            raise Exception, "Missing merger tag in datatype tag"
        self.output_name=elem.get("output_name")
        if not self.output_name:
            raise Exception, "Missing output name tag in datatype tag"
        log.debug(self.output_name)
    
    def get_merger(self):
        return self.merger
    def get_splitter(self):
        return self.splitter
    def get_format(self):
        return self.format
    def get_output_name(self):
        return self.output_name

class GridTool(object):

    def __init__(self,elem,app):
        self.app = app
        self.id = ''
        self.paths={}
        #THINK ABOUT A BETTER WAY TO DO MERGING AND SPLITTING#
        self.input_datatypes = []
        self.parse(elem)


    def is_parralel(self):
        if len(self.input_datatypes) > 0:
            return True
        else:
            return False
    def parse(self, elem):
        """ Parse GridTool parametrs"""
        self.id = elem.get("id")
        if not id:
            raise Exception, "Missing value tag in tool element"
        paths=elem.find("paths")
        if paths:
            self.parse_paths(paths)
        input_datatypes = elem.find("input_datatypes")
        if  input_datatypes:
            self.parse_datatypes(input_datatypes)

    def parse_paths(self,paths):
        for _, path in enumerate(paths):
            source = path.get("src")
            if not source:
                raise Exception, "Missing src tag in path element"
            dest = path.get("dest")
            if not dest:
                raise Exception, "Missing dest tag in path element"
            self.paths[source] = dest

    def parse_datatypes(self, input_datatypes):
        for _, datatype in enumerate(input_datatypes):
            input_dt = InputDatatype(datatype,self.app)
            self.input_datatypes.append(input_dt)

    def get_splitters_by_format(self):
        splitters  = {}
        for input_dt in self.input_datatypes:
            splitters[input_dt.get_format()]= input_dt.get_splitter()
        return splitters
    def get_mergers_by_format(self):
        mergers = {} 
        for input_dt in self.input_datatypes:
            mergers[input_dt.get_format()] = input_dt.get_merger()
        return mergers
    def get_output_names_by_merger(self):
        outputs = {}
        for input_dt in self.input_datatypes:
            outputs[input_dt.get_output_name()] = input_dt.get_merger()
        return outputs
    def get_splitting_types_by_name(self):
        return ['Base Pair','Simple']

    def get_paths(self):
        return self.paths
