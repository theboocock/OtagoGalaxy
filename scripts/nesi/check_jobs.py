#!/home/edwardhills/NeSI_Tools/bin/grython
#
# Author: Edward Hills
# Date: 18/12/12
# Descr: Gets all jobs that are running and returns the statuses of each.
#
# job_status_file = argv[1]

from grisu.Grython import serviceInterface as si
from grisu.model import GrisuRegistryManager
import sys
from grisu.control import JobConstants

job_statuses_file = sys.argv[1]

registry = GrisuRegistryManager.getDefault(si)

uem = registry.getUserEnvironmentManager()

jobs = uem.getCurrentJobs(True)

job_statuses = open(job_statuses_file, "w")

for job in jobs:
    
    # Prints string status
    job_status = job.jobname() + ":" + JobConstants.translateStatus(job.getStatus())
    job_statuses.write(job_status + "\n")

job_statuses.close()

sys.exit(0)

