#!DEFAULT_PATH/grython
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



DEFAULT_GROUP = '/nz/nesi'
DEFAULT_QUEUE = 'pan:pan.nesi.org.nz'
DEFAULT_MEMORY = 2147483648 # 2 GB
DEFAULT_WALLTIME = 600 # 10 minutes

current_dir = os.path.abspath(os.path.curdir)
# TODO not use argv like this. use command line args instead
queue           = sys.argv[1]
group           = sys.argv[2]
galaxy_job_id   = sys.argv[3]
jobname_file    = sys.argv[4]
command         = sys.argv[5]
job_script      = sys.argv[6]
input_files     = list()

job_header="""#!/bin/sh
%s
"""
if group == '':
    group = DEFAULT_GROUP
if queue == '':
    queue = DEFAULT_QUEUE

for f in sys.argv[7:]:
    input_files.append(f)

try:
    job = JobObject(si) 
    job.setSubmissionLocation(queue)
    job.setTimestampJobname("galaxy_" + galaxy_job_id)

    job.setMemory(DEFAULT_MEMORY)
    job.setWalltimeInSeconds(DEFAULT_WALLTIME)

    # stop annoying stats from being written to stderr
    job.addEnvironmentVariable("SUPPRESS_STATS", "true")

#create the job script#

except:
    print "Cannot setup the job environment"
    sys.exit(-4)

#create nesi job_script
print job.getJobname()
try:
# save jobname for job
    njn = open(jobname_file, "w")
    njn.write(job.getJobname())
    njn.close()
except:
    print "Cannot write jobname to file"
    sys.exit(-2)

command_arguments = command.split()

new_commandline = ""
for arg in command_arguments:
    if (os.path.exists(arg)) and (os.path.isfile(arg)==True) and (arg not in input_files):
        try:
            job.addInputFileUrl(arg)
            print "Stagin in:  " + arg
        except Exception, e:
            print "Cannot stage in: " + arg
            print e
            job.kill(True)
            sys.exit(-3)
    new_commandline += (os.path.basename(arg) + " ")
print "bash " + job_script.split('/')[-1]
job.setCommandline("bash "+ job_script.split('/')[-1])
try:
    jscript = open(job_script, 'w')
    script = job_header % (new_commandline)
    jscript.write(script)
    jscript.close()
except:
    print "Cannot write job script"
    sys.exit(-5)

try:   
    job.addInputFileUrl(job_script)
except:
    print "Cannot stage nesi job script"
    sys.exit(-5)

#open job file
#stage in the job file
for inputs in input_files:
    try:
        job.addInputFileUrl(inputs)
        print "input: " + inputs
    except Exception, e:
        print "Cannot stage in: " + arg
        print e
        job.kill(True)
        sys.exit(-3)

job.createJob(group)

print "Submitting job..."
try:
    job.submitJob()
except Exception, e:
    # Just catch all exceptions for time being. TODO
    print "Cannot submit job currently."
    print e
    job.kill(True)
    sys.exit(1)

# That's all folks!
sys.exit(0)
