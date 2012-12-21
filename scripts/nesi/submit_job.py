#!/home/edwardhills/NeSI_Tools/bin/grython
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

DEFAULT_GROUP = '/nz/nesi'
DEFAULT_QUEUE = 'pan:pan.nesi.org.nz'

current_dir = os.path.abspath(os.path.curdir)
queue           = sys.argv[1]
group           = sys.argv[2]
galaxy_job_id   = sys.argv[3]
jobname_file    = sys.argv[4]
command         = sys.argv[5]
input_files     = list()

if group == '':
    group = DEFAULT_GROUP
if queue == '':
    queue = DEFAULT_QUEUE

for f in sys.argv[6:]:
    input_files.append(f)

job = JobObject(si) 
job.setSubmissionLocation(queue)
job.setTimestampJobname("galaxy_" + galaxy_job_id)

# stop annoying stats from being written to stderr
job.addEnvironmentVariable("SUPPRESS_STATS", "true")

# save jobname for job
njn = open(jobname_file, "w")
njn.write(job.getJobname())
njn.close()

# NOTE: I only looks at .dat files for now.
command_arguments = command.split()
new_commandline = ""

for arg in command_arguments:
    if arg.endswith(".dat"):
        new_commandline += (" " + os.path.basename(arg))
    else:
        new_commandline += (" " + arg)

job.setCommandline(new_commandline)

for inputs in input_files:
    print inputs
    job.addInputFileUrl(inputs)

job.createJob(group)

print "Submitting job..."
try:
    job.submitJob()
except:
    # Just catch all exceptions for time being. TODO
    print "Cannot submit job currently."
    job.kill(True)
    sys.exit(1)

# That's all folks!
sys.exit(0)
