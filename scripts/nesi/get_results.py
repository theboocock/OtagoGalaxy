#!/home/edwardhills/NeSI_Tools/bin/grython
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

#job = JobObject(si) 

job = JobObject(si, job_name)

# Save stdout and stderr to files to be read by galaxy
out = open(outfile, "w")
out.write(job.getStdOutContent())
out.close()

err = open(errfile, "w")
err.write(job.getStdErrContent())
err.close()

ec = open(error_codefile, "w")
# FIXME -- awaiting Markus to fix it... could be some time
exit_code = job.getStatus(False) - 1000
ec.write(str(exit_code))
ec.close()

# clean it up
job.kill(True)

# That's all folks!
sys.exit(0)
