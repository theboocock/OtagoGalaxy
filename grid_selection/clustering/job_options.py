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
        log.debug(parralelism)

    def parse_parralelism(self,parralelism):
        if parralelism is not None:
            self.is_parralel_var = True
            self.splitting_type =parralelism[1]
            self.splitting_number= parralelism[0]

    def is_parralel(self):
        return self.is_parralel_var
    def get_splitting_type(self):
        return self.splitting_type
    def get_splitting_number(self):
        return self.splitting_number
        
class JobOptions(object):

    def __init__(self,app,parralelism,queues,advanced):
        self.app = app
        self.parralelism = ParralelismOptions(app,parralelism)
        self.queues = queues
        self.advanced = advanced



    def get_parralelism(self):
        return self.parralelism


