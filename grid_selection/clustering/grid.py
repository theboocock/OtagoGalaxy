"""
    Grid Class Encapsulates all the information for a galaxy grid

    Date: January 2013
    Author: James Boocock

"""

#Python Imports
import os
import sys
import logging

#Clustering Module Imports
import util
import grid_tool

from elementtree import ElementTree

log = logging.getLogger(__name__)

class Grid(object):
    """ Class that encapsulates every individual grid object and contains all
        the information that is needed for the clustering interface """
    def __init__(self,elem,app):
        self.app = app
        self.name = ""
        self.id = ""
        self.runner=""
        self.default_runner_url= ""
        self.queues={}
        self.galaxy_options={}
        self.projects={}
        # Run all tools parameter will be set in any grid where an identical NFS
        # mount is avaliable
        self.run_all_tools=False
        self.overwrite_galaxy_config=False
        # something like self.runtime to encapsulate information about galaxy options
        # Have not decided what to do for each.
        # 
        self.runtime = {}
        #Tool mapping from galaxy tool id to with the rules for the grid
        self.grid_tools={}
        self.parse(elem)
    
    def parse(self,elem):
        """Parse a grid specification xml format """
        #Get the visible name for this tool
        self.name=elem.get("name")
        if not self.name:
            raise Exception, "Missing grid name"
        #Get the unique id for this grid
        self.id=elem.get("id")
        if not self.id:
            raise Exception, "Missing grid id"
        #Get the default_runner_url
        self.default_runner_url=elem.get("default_runner_url")
        if not self.default_runner_url:
            raise Exception, "Missing runner url for grid"
        #Get the runner
        self.runner=elem.get("runner")
        if not self.runner:
            raise Exception, "Missing runner name"
        #Get the run_all_tools option
        self.run_all_tools=util.string_as_bool(elem.get("enable_all_tools","False"))
        #Get the overwrite galaxy options
        self.overwrite_galaxy_config=util.string_as_bool(elem.get("overwrite_galaxy_conf","False"))
        #Get all the galaxy options to be set in the app config
        self.parse_galaxy_config(elem.find("config"))
        #Get all the galaxy queues to be set in the app config
        self.parse_queues(elem.find("queues"))
        #Get all the galaxy runtime options to be provided to the user through the interface.
        self.parse_runtime_options(elem.find("runtime"))
        sefl.parse_runtime_options(elem.find("project"))
        #DEBUG PRINTS
        log.debug(self.runtime)
        log.debug(self.app)
        log.debug(self.name)
        log.debug(self.id)
        log.debug(self.runner)
        log.debug(self.default_runner_url)
        log.debug(self.queues)
        log.debug(self.galaxy_options)
        # Run all tools parameter will be set in any grid where an identical NFS
        # mount is avaliable
        log.debug(self.run_all_tools)
        log.debug(self.overwrite_galaxy_config)

    def parse_galaxy_config(self,elem):
        """Parse galaxy grid options and set them in the galaxy app config"""
        if elem is not None:
            for _, conf_elem in enumerate(elem):
                name = conf_elem.get("name")
                if not name:
                    raise Exception, "Missing name tag in config element" + str(conf_elem)
                value = conf_elem.get("value")
                if not value:
                    raise Exception, "Missing value tag in config element" + str(conf_elem)
                self.galaxy_options[name]=value
                if not self.overwrite_galaxy_config:
                    if not hasattr(self.app.config, self.name):
                        log.warn("conflicting configuration settings found in galaxy for setting {0}, using the".format(name) + " config found in the galaxy settings")
                    else:
                        setattr(self.app.config,name,value)
                        log.debug("Set {0} option for grid {1}".format(name,self.name))
                else:
                   setattr(self.app.config,name,value)
                   log.debug("Set {0} option for grid {1}".format(name,self.name))

    def parse_queues(self, elem):
        """Parse grid queues tags and add them to grid object """
        if elem is not None:
            for _, queue_elem in enumerate(elem):
                name = queue_elem.get("name")
                if not name:
                    raise Exception, "Missing name tag in queue element" + str(queue_elem)
                value= queue_elem.get("value")
                if not value:
                    raise Exception, "Missing value tag in queue element" + str(queue_elem)
                self.queues[name] = value

    def parse_runtime_options(self,elem):
        """Parse run time options for a grid"""

        #TODO MAKE THIS WORK LEAVE AS STUB FOR NOW
        #TEST THIS DUNNO WHAT IS PARSED WHEN THE GRAB FAILS
        if elem is not None: 
            for _, runtime_elem in enumerate(elem):
                name= runtime_elem.get("name")
                if not name:
                    raise Exception, "Missing name tag in runtime option"
                label= runtime_elem.get("value")
                #DEBUG
                if not label:
                    label=""
                type_of_runtime=runtime_elem.get("format")
                if not type_of_runtime:
                    raise Exception, "Missing format tag in runtime option"
    
    def parse_project(self,elem):
        """ Parse project paramters for a grid"""

        if elem is not None:
            for _, runtime_elem in enumerate(elem):
                name = runtime_elem.get("name")
                if not name:
                    raise Exception, "Missing name tag in project option"
                label= runtime_elem.get("value")
                if not label:
                    raise Exception, "Missing value tag in project option"
                self.projects[name]=value

    """Accessors"""

    def get_galaxy_default_runner_url(self):
        return self.default_runner_url
    def get_queues(self):
        return self.queues
    def get_galaxy_options(self):
        return self.galaxy_options
    def check_tool_is_avaliable(self):
        return self.run_all_tools
