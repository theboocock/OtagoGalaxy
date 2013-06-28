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
DEFAULT_MEMORY = 21474836480# 8 GB
DEFAULT_WALLTIME = 6000 # 10 minutes

current_dir = os.path.abspath(os.path.curdir)
# TODO not use argv like this. use command line args instead
queue           = sys.argv[1]
group           = sys.argv[2]
galaxy_job_id   = sys.argv[3]
jobname_file    = sys.argv[4]
command         = sys.argv[5]
job_script      = sys.argv[6]
working_directory = sys.argv[7]
input_files     = list()

job_header="""#!/bin/sh
%s
"""
if group == '':
    group = DEFAULT_GROUP
if queue == '':
    queue = DEFAULT_QUEUE

for f in sys.argv[8:]:
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
try:
# save jobname for job
    njn = open(jobname_file, "w")
    njn.write(job.getJobname())
    njn.close()
except:
    print "Cannot write jobname to file"
    sys.exit(-2)

command_arguments = command.split()

print input_files
new_commandline = ""
file = open("/home/jamesboocock/blah.txt", 'a')
for arg in command_arguments:
    file.write(arg + '\n')
    arg=arg.replace('"','')
    print("arg: " + arg)
    if ((os.path.exists(arg)) or (os.path.isfile(arg)==True)) and (arg not in input_files) and ("_file" not in arg):
        try:
            job.addInputFileUrl(arg)
            print "Stagin in:  " + arg
            file.write("stagin in 1" + arg + '\n')
        except Exception, e:
            print "Cannot stage in: " + arg
            print e
            job.kill(True)
            sys.exit(-3)
    elif ((os.path.exists(arg)) or (os.path.isfile(arg)==True)) and (arg not in input_files) and ("_file" in arg):
        try:
            folder=arg.split('/')[len(arg.split('/'))-2]
            fil= arg.split('/')[len(arg.split('/'))-1]
            argupdate=os.path.join(working_directory,os.path.join((folder.split('.')[0]), fil))
            print "argupdate "  + argupdate
            if(os.path.isfile(argupdate)):
                print "Stagin in:  " + argupdate
                file.write(argupdate + "did it work???")
                file.write("stagin in 2 " + argupdate + '\n')
                job.addInputFileUrl(argupdate)
            else:
                print "Stagin in:  " + arg
                file.write("stagin in 3" + arg + '\n')
                file.write("arg update " + argupdate  + '\n')
                file.write("os path join" + os.path.join(folder.split('.')[0], fil))
                job.addInputFileUrl(arg)
        except Exception, e:
            print "Cannot stage in: " + arg
            print e
            job.kill(True)
            sys.exit(-3)
    #Ensure we strip the basename of any files that exist or any files that will  exist
    if(os.path.exists(arg)) or (os.path.exists('/'.join(arg.split('/')[:len(arg.split('/'))-1]))):
        new_commandline += (os.path.basename(arg) + " ")
    else:
        new_commandline += (arg + " ")
print job_header % (new_commandline)
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
