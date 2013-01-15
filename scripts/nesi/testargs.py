#!/home/jamesboocock/NeSI_Tools/bin/grython
# FIXME: need an installer type thing to do ^^ correctly
#
# Author: Ed hills
# Date: 17/12/12
# Descr: This grython script will submit a job to the NeSI grid. This has not
#        been made for batch jobs, only single jobs. Still early design. Is not
#        complete.

# Arguments:
# argv1     = queue
# argv2     = group
# argv3     = galaxy job id 
# argv4     = file to write jobname to
# argv5     = command line
# argv6-n   = files to be staged in

# TODO: !! Add tool specific walltime !!
# TODO: !! Add tool specific memory usage !! 

# TODO: add possibiility for emailing user if defined in galaxy config
# TODO: get application and check that it is ok to run on queue

from grisu.Grython import serviceInterface as si
from grisu.frontend.control.login import LoginManager
from grisu.frontend.model.job import JobObject, BatchJobObject, JobsException
from grisu.model import FileManager
from grisu.jcommons.constants import Constants
import time
import sys
import os

for item in sys.argv:
    print item
