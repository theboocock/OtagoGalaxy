"""

    Job Options defines all the options 
    for each individual job this is parsed
    directly from the interface creates an object
    that represents everything that is required to perform the computation


    @author JamesBoocock

"""

class ParralelismOptions(object):
    
    def __init__(self,app,parralelism):
        self.app = app
        is_parrelel = False
        splitting_number = 0
        splitting_type = ''
        parse_parralelism(parralelism)


    def parse_parralelism(self,parralelism):
        if parralelism is not None:
            is_parrelel = True
            splitting_type =parralelism[1]
            splitting_number= parralelism[0]

    def is_parrelel(self):
        return self.is_parrelel
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
