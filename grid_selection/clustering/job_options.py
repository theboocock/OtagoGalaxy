"""

    Job Options defines all the options 
    for each individual job this is parsed
    directly from the interface creates an object
    that represents everything that is required to perform the computation


    @author JamesBoocock

"""

import sys
import logging

log = logging.getLogger(__name__)

class ParralelismOptions(object):
    
    def __init__(self,app,parralelism):
        self.app = app
        self.is_parralel_var = False
        self.splitting_number = 0
        self.splitting_type = ''
        self.parse_parralelism(parralelism)

    def parse_parralelism(self,parralelism):
        if parralelism is not None:
            self.is_parralel_var = True
            for values in parralelism:
                if values == "Base Pair":
                    self.splitting_type = 'bp'
                elif values == "Simple":
                    self.splitting_type ="simple"
                else:
                    self.splitting_number = values
            if self.splitting_type == 'bp':
                log.debug(self.splitting_number)
                split_option = self.splitting_number.split(':')
                log.debug(split_option)
                self.splitting_number = split_option[0]
                self.splitting_type = split_option[1]

    def is_parralel(self):
        return self.is_parralel_var
    def get_splitting_type(self):
        return self.splitting_type
    def get_splitting_number(self):
        return self.splitting_number
        
class JobOptions(object):

    def __init__(self,app,incoming):
        self.grid =None
        self.parralelism = []
        self.queues = None
        self.advanced = None
        self.app = app
        self.parse_incoming(incoming)
        self.parralelism_options = ParralelismOptions(self.app,self.parralelism)

    def parse_incoming(self,incoming):
        log.debug(incoming)
        if incoming is not None:
            for key,value in incoming.items():        
                if key == "grid":
                    self.grid = str(value)
            for key,value in incoming.items():
                if key.split('+')[0] == self.grid:
                    self.parralelism.append(str(value))
        log.debug(self.parralelism)
        log.debug(self.grid)


    def get_parralelism(self):
        return self.parralelism_options

    def get_grid(self):
        return self.grid
