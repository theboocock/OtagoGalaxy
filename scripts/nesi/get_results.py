#!/home/edwardhills/NeSI_Tools/bin/grython -b BeSTGRID
#
# Author: Ed hills
# Date: 17/12/12
# Descr: This grython script will return the files created by a NeSI job. This has not
#        been made for batch jobs, only single jobs. Still early design. Is not
#        complete.

# Arguments:
# argv1     = queue
# argv2     = group
# argv3     = galaxy job id 
# argv4     = command line
# argv5-n   = files to be staged in

# TODO: add possibiility for emailing user if defined in galaxy config
# TODO: get application and check that it is ok to run on queue

from grisu.Grython import serviceInterface as si
from grisu.frontend.control.login import LoginManager
from grisu.frontend.model.job import JobObject, BatchJobObject, JobsException
from grisu.model import FileManager
from grisu.jcommons.constants import Constants
import sys
import os

DEFAULT_GROUP = '/nz/nesi'
DEFAULT_QUEUE = 'pan:pan.nesi.org.nz'

current_dir = os.path.abspath(os.path.curdir)

# get the files that i should have
outfile         = sys.argv[1]
errfile         = sys.argv[2]
error_codefile  = sys.argv[3]
job_name        = sys.argv[4]

job = JobObject(si) 

job = job.getJob(job_name)

# Save stdout and stderr to files to be read by galaxy
with open(outfile, "w") as out:
    out.write(job.getStdOutContent())

with open(errfile, "w") as err:
    err.write(job.getStdErrContent()

with open(error_codefile, "w") as err:
    err.write(job.getErrorCode()

# TODO do i need to do clean here?
job.kill(True)

# That's all folks!
exit(0)
