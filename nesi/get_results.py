#!DEFAULT_PATH/grython
# FIXME: need an installer type thing to do ^^ correctly
#
# Author: Ed hills
# Date: 17/12/12
# Descr: This grython script will return the files created by a NeSI job. This has not
#        been made for batch jobs, only single jobs. Still early design. Is not
#        complete.

# Arguments:
# argv1     = ofile
# argv2     = efile
# argv3     = ecfile
# argv4     = job_name

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
output_files    = list()
print job_name
# get list of output files for this job
for f in sys.argv[5:]:
    output_files.append(f)

job = JobObject(si, job_name)

# Save stdout and stderr to files to be read by galaxy
try:
    out = open(outfile, "w")
    out.write(job.getStdOutContent())
    out.close()

    err = open(errfile, "w")
    try:
        err.write(job.getStdErrContent())
    except:
        # There is no stderr so just write blank file
        err.write("")
    err.close()

    ec = open(error_codefile, "w")
    exit_code = job.getStatus(False) - 1000
    ec.write(str(exit_code))
    ec.close()

    for f in output_files:
        try:
            of = open(f, "w")
            rel_f = os.path.basename(f)
            of.write(job.getFileContent(rel_f))
            of.close()
        except:
            print "Cannot find file " + rel_f
            sys.exit(-3)

except:
    print "Cannot open files to write results to"
    sys.exit(-2)

# clean it up
job.kill(True)

# That's all folks!
sys.exit(0)
