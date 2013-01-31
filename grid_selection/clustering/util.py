"""
    Utility functions for the galaxy clustering module

    Author James Boocock

"""

from elementtree import ElementTree, ElementInclude

def parse_xml(fname):
        """Parse XML file using elemenTree"""
        tree=ElementTree.parse(fname)
        root=tree.getroot()
        ElementInclude.include(root)
        return tree

    #parse and create each individual grid object
def string_as_bool(string):
    if str(string).lower() in ('true' 'on' 'yes'):
        return True
    else:
        return False
