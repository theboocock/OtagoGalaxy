#!/home/jamesboocock/NeSI_Tools/bin/grython
# FIXME: need an installer type thing to do ^^ correctly
#
# Author: Ed hills
# Date: 17/12/12
# Descr: This grython script will stop a job running on a NeSI queue. This has not
#        been made for batch jobs, only single jobs. Still early design. Is not
#        complete.

# Arguments:
# argv1     = job_name 

from grisu.Grython import serviceInterface as si
from grisu.frontend.control.login import LoginManager
from grisu.frontend.model.job import JobObject, BatchJobObject, JobsException
import sys

DEFAULT_GROUP = '/nz/nesi'
DEFAULT_QUEUE = 'pan:pan.nesi.org.nz'

job_name   = sys.argv[1]

try:
    si.kill(job_name, True)
except Exception:
    print "Can not kill job: ",e
    sys.exit(1)

# That's all folks!
sys.exit(0)
