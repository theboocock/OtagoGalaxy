import logging, os, sys, time, tempfile , shutil, string, glob
import data
from galaxy import util
from cgi import escape
import urllib, binascii
from galaxy.web import url_for
from galaxy.datatypes import metadata
from galaxy.datatypes.metadata import MetadataElement
from galaxy.datatypes.data import Text
from galaxy.datatypes.images import Html
from galaxy.datatypes.interval import Interval
from galaxy.util.hash_util import *

log = logging.getLogger(__name__)

class ImputeDatatypes(Html):
    """
    Base class for impute2 data types
    derived from html -composite datatype elements
    stroed in extra files path
 """
    MetadataElement( name="base_name", desc="base name for all transformed versions of this genetic dataset", default='ImputeData',
    readonly=True, set_in_upload=True)
    log.debug("WHAT IN THE FUCKA") 
    composite_type = 'auto_primary_file'
    allow_datatype_change = False
    file_ext = 'impute'

    def generate_primary_file( self, dataset = None ):
        rval = ['<html><head><title>Otago Impute2 Datatypes </title></head><p/>']
        rval.append('<div>This composite dataset is composed of the following files:<p/><ul>')
        for composite_name, composite_file in self.get_composite_files( dataset = dataset ).iteritems():
            fn = composite_name
            opt_text = ''
            if composite_file.optional:
                opt_text = ' (optional)'
            if composite_file.get('description'):
                rval.append( '<li><a href="%s" type="application/binary">%s (%s)</a>%s</li>' % ( fn, fn, composite_file.get('description'), opt_text ) )
            else:
                rval.append( '<li><a href="%s" type="application/binary">%s</a>%s</li>' % ( fn, fn, opt_text ) )
        rval.append( '</ul></div></html>' )
        return "\n".join( rval )

    def regenerate_primary_file(self,dataset):
        """
        cannot do this until we are setting metadata 
        """
        bn = dataset.metadata.base_name
        efp = dataset.extra_files_path
        flist = os.listdir(efp)
        rval = ['<html><head><title>Files for Composite Dataset %s</title></head><body><p/>Composite %s contains:<p/><ul>' % (dataset.name,dataset.name)]
        for i,fname in enumerate(flist):
            sfname = os.path.split(fname)[-1] 
            f,e = os.path.splitext(fname)
            rval.append( '<li><a href="%s">%s</a></li>' % ( sfname, sfname) )
        rval.append( '</ul></body></html>' )
        f = file(dataset.file_name,'w')
        f.write("\n".join( rval ))
        f.write('\n')
        f.close()

    def get_mime(self):
        """Returns the mime type of the datatype"""
        return 'text/html'


    def set_meta( self, dataset, **kwd ):

        """
        for lped/pbed eg

        """
        Html.set_meta( self, dataset, **kwd )
        if kwd.get('overwrite') == False:
            return True
        try:
            efp = dataset.extra_files_path
        except: 
            return False
        try:
            flist = os.listdir(efp)
        except:
            return False
        if len(flist) == 0:
            return False
        self.regenerate_primary_file(dataset)
        if not dataset.info:           
                dataset.info = 'Galaxy Impute2 datatype object'
        if not dataset.blurb:
               dataset.blurb = 'Composite file - Otago Impute2 Galaxy toolkit'
        return True

class Gtool(ImputeDatatypes):
    """ 
    gen and sample file impute2 data collections
    """
    def __init__(self, **kwd):
        ImputeDatatypes.__init__(self, **kwd)
        self.add_composite_file('%s.gen',description= " Gtool Genotypes File (.gen)", substitute_name_with_metadata='base_name', is_binary=False)
        self.add_composite_file('%s.sample', description= " Gtool Sample File (.sample)", substitute_name_with_metadata="base_name", is_binary=False)

class Impute(ImputeDatatypes):
    ""
    def __init__(self, **kwd):
        ImputeDatatypes.__init__(self, **kwd)
        self.add_composite_file('%s.gen', description= " Impute 2 Genotypes File (.gen)", substitute_name_with_metadata='base_name', is_binary=False)
        self.add_composite_file('%s.sample', description= " Impute 2 Sample File (.sample)", substitute_name_with_metadata="base_name", is_binary=False)

class ShapeIt(ImputeDatatypes):
    ""
    def __init__(self, **kwd):
        ImputeDatatypes.__init__(self, **kwd)
        self.add_composite_file('%s.haps', description= "Shape It Haplotypes File (.haps)" , substitute_name_with_metadata='base_name', is_binary=False)
        self.add_composite_file('%s.sample', description= "Shape It Sample Information File (.sample)", substitute_name_with_metadata='base_name', is_binary=False)
class Ihs(ImputeDatatypes):
    ""
    def __init__(self, **kwd):
        ImputeDatatypes.__init__(self, **kwd)
        self.add_composite_file('%s.ihshap', description= "Ihs Haplotype File" , substitute_name_with_metadata='base_name', is_binary=False)
        self.add_composite_file('%s.ihsmap', description= "Ihs Map File", substitute_name_with_metadata='base_name', is_binary=False)
