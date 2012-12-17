#!/home/edwardhills/NeSI_Tools/bin/grython -b BeSTGRID
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
queue           = sys.argv[1]
group           = sys.argv[2]
galaxy_job_id   = sys.argv[3]
command         = sys.argv[4]
input_files     = list()

if group == '':
    group = DEFAULT_GROUP
if queue == '':
    queue = DEFAULT_QUEUE

for f in sys.argv[6:]:
    input_files.append(f)


#TODO - think about how exactly files are going to work.. what about files already staged on the nesi server?

#FIXME why isn't it catting my files properly? its the same as there example..

job = JobObject(si) 
job.setSubmissionLocation(queue)
job.setTimestampJobname("galaxy_" + galaxy_job_id)

# save jobname for job
with open("nesi_job_name.tmp", "w") as njn:
    njn.write(job.getJobName())

job.setCommandline(command)

for inputs in input_files:
    job.addInputFileUrl(inputs)

job.createJob(group)

print "Submitting job..."
try:
    job.submitJob()
except Exception, e:
    # Just catch all exceptions for time being. TODO
    print "Cannot submit job currently."
    job.kill(True)
    exit(1)

while not job.isFinished():
    time.sleep(3)

print "standard out: \n", job.getStdOutContent()
print "standard out: \n", job.getStdErrContent()

# That's all folks!
exit(0)
