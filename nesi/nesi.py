import os, logging, threading, time, traceback
from datetime import timedelta
from Queue import Queue, Empty

from galaxy import model
from galaxy.jobs.runners import BaseJobRunner

from paste.deploy.converters import asbool
import pkg_resources
import shutil

from subprocess import call

#TODO get this to check if scripts exist
# TODO get this to check if grython is installed correctly
# ^^ this may change if we switch to the deb package..

egg_messages = """
The 'nesi' runner depends on 'grython' which is not installed or not configured properly.
For this job runner to work a mac version of galaxy is required and that the 
Additional Errors may follow:
%s
"""

log = logging.getLogger(__name__)

__all__ = ['NesiJobRunner']

# possible job statuses
job_status= {
    0: "Done",
    1: "Pending",
    2: "Failed",
    3: "Active",
    4: "No such job",
    5: "Job created",
    6: "Ready to submit",
    7: "Staging in",
    8: "Unsubmitted",
    9: "Cleaning up",
    10: "Job killed",
}

class NesiJobState( object ):
    def __init__( self ):
        """
        Encapsulates state related to a job that is being run via Nesi and 
        what we need to monitor for each job.
        """
        self.job_wrapper = None
        self.job_name = None
        self.old_state = None 
        self.running = False
        self.ofile = None
        self.efile = None
        self.ecfile = None
        self.nesi_jobname_file = None
        self.runner_url = None
        self.check_count=0
        self.stop_job = False
        self.wall_time_mins = 0

class NesiJobRunner(BaseJobRunner):
    """
    Job Runner Backed by a finite pool of worker threads. FIFO scheduling
    """
    STOP_SIGNAL=object()

    def __init__(self, app):
        """Initialize this job runner and start monitor thread"""
        self.app=app
        self.sa_session=app.model.context
        self.watched=[]
        self.monitor_queue=Queue()
        self.default_nesi_grid=self.determine_nesi_runner(self.app.config.nesi_default_server)
        self.default_nesi_server=self.determine_nesi_server(self.app.config.nesi_default_server)
        self.nesi_group=self.determine_nesi_group(self.app.config.nesi_group)
        self.monitor_thread = threading.Thread(target=self.monitor)
        self.monitor_thread.start()
        self.work_queue=Queue()
        self.work_threads =[] 
        nworkers = app.config.cluster_job_queue_workers
        for i in range(nworkers):
            worker =threading.Thread(target=self.run_next)
            worker.start()
            self.work_threads.append(worker)
        log.debug ("%d workers ready" % nworkers)

    """
    Nesi server determination takes the parameter url specified in the 
    default_cluster_runner for now
    
    Format is up to the galaxy wiki standards.
    """
    def determine_nesi_runner(self, url, rewrite=False):
        """Determine what Nesi cluster we are connecting to"""
        url_split=url.split("/")
        runner = url_split[0]
        if runner == "":
            if not self.default_nesi_runner:
                self.default_nesi_runner = None
                log.debug("Set default nesi runner to %s" % self.default_nesi_runner)
            runner = self.default_nesi_runner
        if runner is None:
            raise Exception("Could not find nesi runner")
        if rewrite:
            return (runner, "/".join(url_split))
        else: 
            return runner

    def determine_nesi_server(self, url, rewrite=False):
        """Determine what Nesi server we are connecting to"""
        url_split=url.split("/")
        server = url_split[2]
        if server =="":
            if not self.default_nesi_server:
                self.default_nesi_server =None
                log.debug("Set default nesi server to %s" % self.default_nesi_server)
            server = self.default_nesi_server
        if server is None:
            raise Exception("Could not find nesi server")
        if rewrite:
            return (server , "/".join(url_split))
        else: 
            return server

    def determine_nesi_group(self, group, rewrite=False):
        """Determine what Nesi group we are connecting to"""
        nesi_group = group
        if nesi_group == "" or None:
            self.nesi_group = '/nz/nesi'
            log.debug("No group set. Setting NeSI group to %s" % self.nesi_group)
            nesi_group = self.nesi_group
        else: 
            return nesi_group

    def monitor(self):
        """
        Watches all jobs currently in the nesi queue and deals with state changes
        (queued to running) and job completion
        """
        while 1:
            #take any new jobs and put them on the monitor list.
            try:
                while 1:
                    nesi_job_state=self.monitor_queue.get_nowait()
                    if nesi_job_state is self.STOP_SIGNAL:
                        self.cleanup()
                        return
                    self.watched.append(nesi_job_state)
            except Empty:
                pass 

            #Iterate over the list of watched jobs and check state.
            if len(self.watched) > 0:
                try:
                    self.check_watched_items()
                except:
                    log.exception("Uncaught exception checking jobs")

            #sleep a bit before the next state is checked
            time.sleep(5)

    def check_watched_items(self):
        """Called by the monitor thread to look at each of the jobs and deal 
            with state changes"""
        new_watched=[]
        log.debug(self.watched)
        nesi_server= self.determine_nesi_server(self.app.config.default_cluster_job_runner)
        nesi_runner= self.determine_nesi_runner(self.app.config.default_cluster_job_runner)
        nesi_script_location = os.path.abspath(self.app.config.nesi_scripts_directory)
        jobstatus_file = os.path.abspath(nesi_script_location + "/jobstatus_file.tmp")
        
        rc = call(nesi_script_location + "/./check_jobs.py " + "-b BeSTGRID " + jobstatus_file, shell=True)

        if rc == -2:
            log.debug("Call failed: " + nesi_script_location + "/./check_jobs.py" + " -b BeSTGRID" + " " + jobstatus_file)
            log.error("Could not write job statuses to %s file." % jobstatus_file)
            return

        if rc == -1:
            log.debug("Call failed: " + nesi_script_location + "/./check_jobs.py" + " -b BeSTGRID" + " " + jobstatus_file)
            log.error("%s was not provided." % jobstatus_file)
            return

        if rc != 0:
            log.debug("Call failed: " + nesi_script_location + "/./check_jobs.py" + " -b BeSTGRID" + " " + jobstatus_file)
            log.error("Could not check NeSI servers to obtain job statuses")
            return

        for nesi_job_state in self.watched:
            job_name = nesi_job_state.job_name
            galaxy_job_id = nesi_job_state.job_wrapper.get_id_tag()
            old_state = nesi_job_state.old_state
            try: 
                with open(jobstatus_file, "r") as njs:
                    status = ""
                    for line in njs:
                        line = line.split(":")
                        state_jobname = line[0]
                        if state_jobname == job_name:
                            status = line[1].strip()
                            break

                    if status == "":
                        log.error("Could not find job in NeSI queue that matched: %s" % job_name)
                        self.work_queue.put(('fail', nesi_job_state))

            except:
                print "Call failed: " + nesi_script_location + "/./check_jobs.py" + " -b BeSTGRID" + " " + jobstatus_file
                log.exception("Could not access jobs to check job status.")
                return

            log.debug("Status for " + job_name + " is: " + status) 
            if status != old_state:          
                log.debug("(%s/%s) NeSI Jobs state changed from %s to %s" % (galaxy_job_id, job_name,old_state,status))
            if status == "Active" and not nesi_job_state.running:
                nesi_job_state.old_state=job_status[3]
                nesi_job_state.running=True
                nesi_job_state.job_wrapper.change_state(model.Job.states.RUNNING)
                new_watched.append(nesi_job_state)
            elif status == "Active" and nesi_job_state.running:
                nesi_job_state.old_state=job_status[3]
                new_watched.append(nesi_job_state)
            elif (status == "Failed") or (status == "Job killed") or (status == "Undefined"):
                log.debug("Old state: %s is now %s and put into fail queue." % (old_state, status))
                nesi_job_state.old_state=job_status[2]
                self.work_queue.put(('fail', nesi_job_state))
            if status == "Done":
                log.debug("Adding job %s to finish queue" % nesi_job_state.job_name)
                nesi_job_state.old_state=job_status[0]
                self.work_queue.put(('finish',nesi_job_state))
            else:
                log.debug("Appending new nesi_job_state")
                new_watched.append(nesi_job_state)

        self.watched= new_watched

    def queue_job(self, job_wrapper):
        """Queue a nesi job"""
        try:
            job_wrapper.prepare()
            command_line=self.build_command_line(job_wrapper)
        except:
            job_wrapper.fail("Failure preparing job", exception=True)
            log.exception("Failure running job %d" % job_wrapper.job_id)
            return

        runner_url= job_wrapper.get_job_runner_url()
        #Make sure we dont queue job with no command line
        if not command_line:
            job_wrapper.finish('','')

        # Check for deletion before we change state
        if job_wrapper.get_state() == model.Job.states.DELETED:
            log.debug("Job %s deleted by user before it entered the nesi queue" % job_wrapper.job_id)
            if self.app.config.cleanup_job in ("always", "onsuccess"):
                job_wrapper.cleanup()
            return

        runner_url=job_wrapper.get_job_runner_url()
        nesi_server=self.determine_nesi_server(runner_url)
        nesi_script_location = os.path.abspath(self.app.config.nesi_scripts_directory)
        jobstatus_file = os.path.abspath(nesi_script_location + "/jobstatus_file.tmp")
        ecfile = "%s/%s.ec" % (self.app.config.cluster_files_directory, job_wrapper.job_id)
        ofile  = "%s/%s.o" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        efile = "%s/%s.e" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        nesi_jobname_file = "%s/%s.njf" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        job_script= "%s/%s.sh" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        exec_dir = os.path.abspath( job_wrapper.working_directory )

        if job_wrapper.get_state() == model.Job.states.DELETED:
            log.debug("Job %s deleted by user before it entered the Nesi queue" % job_wrapper.job_id)
            if self.app.config.cleanup_job in ("always", "onsuccess"):
                job_wrapper.cleanup((ofile,efile,ecfile,nesi_jobname_file, jobstatus_file))
            return

        #submit
        galaxy_job_id = job_wrapper.get_id_tag()
        log.debug("(%s) Submitting: %s" % (galaxy_job_id, command_line))
               
        input_files = " ".join(job_wrapper.get_input_fnames())
        #Submit the job to nesi
        rc = call(nesi_script_location + "/./submit_job.py" + " -b BeSTGRID " + nesi_server + " " + self.nesi_group + " " + galaxy_job_id + " " + nesi_jobname_file + " '" + command_line + "' " +" " + job_script + " "  +input_files, shell=True)
        if rc == -2:
            job_wrapper.fail("NeSI job submitter returned an unsuccessful error code. Unable to submit NeSI job currently.")
            log.error("Jobname file could not be created. Cannot submit NeSI job currently.")
            log.debug("Call: " + nesi_script_location + "/./submit_job.py" + " -b BeSTGRID " + nesi_server + " " + self.nesi_group + " " + galaxy_job_id + " " + nesi_jobname_file + " '" + command_line + "' " +  job_script + " " + input_files)
            return

        if rc == -3:
            job_wrapper.fail("NeSI job submitter returned an unsuccessful error code. Unable to stage in files.")
            log.error("Could not stage in files. Cannot submit NeSI job currently.")
            log.debug("Call: " + nesi_script_location + "/./submit_job.py" + " -b BeSTGRID " + nesi_server + " " + self.nesi_group + " " + galaxy_job_id + " " + nesi_jobname_file + " '" + command_line + "' "  + job_script + " " + input_files)
            return

        if rc != 0:
            job_wrapper.fail("NeSI job submitter returned an unsuccessful error code. Unable to submit NeSI job currently.")
            log.error("Cannot submit NeSI job currently.")
            log.debug("Call: " + nesi_script_location + "/./submit_job.py" + " -b BeSTGRID " + nesi_server + " " + self.nesi_group + " " + galaxy_job_id + " " + nesi_jobname_file + " '" + command_line + "' "  + job_script + " " + input_files)
            return

        # get nesi jobname
        try:
            njn = open(nesi_jobname_file, 'r')
            nesi_job_name = njn.readline()
            njn.close()
        except:
            job_wrapper.fail("Unable to submit NeSI job currently.")
            log.error("NeSI job file not created correctly.")

        # store runner information for tracking if Galaxy restarts.
        job_wrapper.set_runner(runner_url, nesi_job_name)
        # Store nesi related state information for job.
        nesi_job_state=NesiJobState()
        nesi_job_state.job_wrapper = job_wrapper
        nesi_job_state.job_name= nesi_job_name
        nesi_job_state.ecfile=ecfile
        nesi_job_state.old_state= job_status[1]
        nesi_job_state.running=False
        nesi_job_state.runner_url=runner_url 
        nesi_job_state.ofile = ofile
        nesi_job_state.efile = efile
        nesi_job_state.nesi_jobname_file=nesi_jobname_file

        # Add to our queue of jobs to monitor
        self.monitor_queue.put(nesi_job_state)

    def run_next( self ):
        """
        Run the next item in the queue (a job waiting to run or finish )
        """
        while 1:
            ( op, obj ) = self.work_queue.get()
            if op is self.STOP_SIGNAL:
                return
            try:
                if op == 'queue':
                    self.queue_job( obj )
                elif op == 'finish':
                    self.finish_job( obj )
                elif op == 'fail':
                    self.fail_job( obj )
            except:
                log.exception( "(%s) Uncaught exception %sing job" % ( getattr( obj, 'job_name', None ), op ) )
    
    def put(self, job_wrapper):
        """Add a job to the queue(by job identifier)"""
        #change the queued state before handing to workthread so the runner won't pick it up again
        job_wrapper.change_state(model.Job.states.QUEUED)
        self.work_queue.put(('queue',job_wrapper))

    def stop_job(self,job):
        """Attempts to remove a job from the Nesi queue"""
    
        nesi_script_location = os.path.abspath(self.app.config.nesi_scripts_directory)

        rc = call(nesi_script_location + "/./stop_job.py " + "-b BeSTGRID " + job.get_job_runner_external_id(), shell=True)

        if rc != 0:
            log.error("Cannot kill job %s" % job.get_job_runner_external_id())
            return

    def finish_job(self, nesi_job_state):
        """Finishes a job sent to nesi"""
        ecfile = nesi_job_state.ecfile 
        ofile = nesi_job_state.ofile
        efile = nesi_job_state.efile
        jobname_file = nesi_job_state.nesi_jobname_file
        runner_url=nesi_job_state.job_wrapper.get_job_runner_url()
        nesi_server=self.determine_nesi_server(runner_url)
        nesi_script_location = os.path.abspath(self.app.config.nesi_scripts_directory)
        jobstatus_file = os.path.abspath(nesi_script_location + "/jobstatus_file.tmp")
        nesi_job_name = nesi_job_state.job_name
        output_fnames = nesi_job_state.job_wrapper.get_output_fnames()
        output_files = [ str( o ) for o in output_fnames]
        output_files = " ".join(output_files)
        
        # get results
        rc = call(nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name + " " + output_files, shell=True)
        
        # can't hit server for some reason
        if rc == -2:
            nesi_job_state.job_wrapper.fail("Cannot currently get results for this job.")
            log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name + " " + output_files)
            log.error("Unable to download and create stderr, stdout, and errorcode files.")
            return

        if rc == -3:
            nesi_job_state.job_wrapper.fail("Cannot currently get results for this job")
            log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name + " " + output_files)
            log.error("Extra files can't be downloaded from NeSI for some reason")
            return
        if rc != 0:
            # lets just sleep for a bit and try again
            time.sleep(10)
            log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name + " " + output_files)
            rc = call(nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name, shell=True)

            if rc == -2:
                nesi_job_state.job_wrapper.fail("Cannot currently get results for this job.")
                log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name + " " + output_files)
                log.error("Unable to download and create stderr, stdout, and errorcode files.")
                return

            if rc != 0:
                # no luck for some reason 
                nesi_job_state.job_wrapper.fail("Cannot get results for this execution")
                log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name + " " + output_files)
                log.error("Cannot get results from NeSI Server")
                return

        try:
            efh=file(efile,"r")
            ofh=file(ofile, "r")
            stdout = ofh.read(32768)
            stderr = efh.read(32768)

        except:
            stdout = ''
            stderr = 'Job output not returned by Nesi: The job was manually dequeued or there was a cluster error'
            log.error("Could not open stdout/stderr files")

        try:
            ecfh = file(ecfile, "r")
            exit_code_str= ecfh.read(32)
            exit_code = int (exit_code_str)
        except:
            exit_code_str=""
            log.warning("Exit code" + exit_code_str + " was invalid or missing, using 0." )
            exit_code = 0

        try:
            nesi_job_state.job_wrapper.finish(stdout, stderr, exit_code)
        except:
            log.exception("Job Wrapper finish method failed")
            nesi_job_state.job_wrapper.fail("Unable to finish job", exception=True)

        if self.app.config.cleanup_job == "always" or ( not stderr and self.app.config.cleanup_job == "onsuccess" ):
            self.cleanup((ecfile,ofile,efile,jobname_file,jobstatus_file))
    
    def fail_job(self, nesi_job_state):
        """Finishes a failed job sent to nesi"""
        ecfile = nesi_job_state.ecfile 
        ofile = nesi_job_state.ofile
        efile = nesi_job_state.efile
        jobname_file = nesi_job_state.nesi_jobname_file
        runner_url=nesi_job_state.job_wrapper.get_job_runner_url()
        nesi_server=self.determine_nesi_server(runner_url)
        nesi_script_location = os.path.abspath(self.app.config.nesi_scripts_directory)
        jobstatus_file = os.path.abspath(nesi_script_location + "/jobstatus_file.tmp")
        nesi_job_name = nesi_job_state.job_name
        
        # get results
        rc = call(nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name, shell=True)
        
        if rc == -2:
            nesi_job_state.job_wrapper.fail("Cannot currently get results for this job.")
            log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name)
            log.error("Cannot create files to write results to.")
            return

        # can't hit server for some reason
        if rc != 0:
            # lets just sleep for a bit and try again
            time.sleep(10)

            rc = call(nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name, shell=True)

            if rc == -2:
                nesi_job_state.job_wrapper.fail("Cannot currently get results for this job.")
                log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name)
                log.error("Cannot create files to write results to.")
                return

            if rc != 0:
                # no luck for some reason 
                log.debug("Failed. Call: " + nesi_script_location + "/./get_results.py" + " -b BeSTGRID " + ofile + " " + efile + " " + ecfile + " " + nesi_job_name)
                nesi_job_state.job_wrapper.fail("Cannot currently get results for this job.")
                log.error("Cannot get results from NeSI Server")
                return

        try:
            efh=file(nesi_job_state.efile,"r")
            ofh=file(nesi_job_state.ofile, "r")
            stdout = ofh.read(32768)
            stderr = efh.read(32768)

        except:
            stdout = ''
            stderr = 'Job output not returned by Nesi: The job was manually dequeued or there was a cluster error'
            log.debug("Could not open stdout/stderr files")

        try:
            ecfh = file(ecfile, "r")
            exit_code_str= ecfh.read(32)
            exit_code = int (exit_code_str)
            print "Exit Code: ", exit_code

        except:
            exit_code_str=""
            log.warning("Exit code" + exit_code_str + " was invalid or missing, using 0." )
            exit_code = 0

        try:
            if stderr == '':
                stderr = "This tool was unable to run on the NeSI Queue. Please contact an administrator"
            nesi_job_state.job_wrapper.fail(stderr, stderr=stderr, stdout=stdout, exit_code=exit_code_str)
        except:
            log.exception("Job Wrapper finish method failed")
            nesi_job_state.job_wrapper.fail("Unable to finish job", exception=True)

        if self.app.config.cleanup_job == "always" or ( not stderr and self.app.config.cleanup_job == "onsuccess" ):
            self.cleanup((ecfile,ofile,efile,jobname_file,jobstatus_file))

    def cleanup( self, files ):
        for file in files:
            try:
                os.unlink( file )
            except Exception, e:
                log.warning( "Unable to cleanup: %s" % str( e ) )

    def recover (self, job,job_wrapper):
        """Recovers jobs stuck in the queued / running state when galaxy started"""
        job_id = job.get_job_runner_external_id()
        if job_id is None:
            self.put(job_wrapper)
            return

        nesi_job_state=NesiJobState()
        nesi_job_state.ofile = "%s/%s.o" % (self.app.config.cluster_files_directory, job.id)
        nesi_job_state.efile = "%s/%s.e" % (self.app.config.cluster_files_directory, job.id)
        nesi_job_state.ecfile = "%s/%s.ec" % (self.app.config.cluster_files_directory, job.id)
        nesi_job_state.job_file = "%s/%s.sh" % (self.app.config.cluster_files_directory,job.id)
        nesi_job_state.job_id=str(job_id)
        nesi_job_state.runner_url=job_wrapper.get_job_runner_url()
        nesi_job_state.job_wrapper= job_wrapper

        if job.state == model.Job.states.RUNNING:
            log.debug ("(%s/%s) is still running, adding to the nesi queue" %(job.id,job.get_job_runner_external_id()))
            nesi_job_state.old_state=nesi_job_state[2]
            nesi_job_state.running = True
            self.monitor_queue.put(nesi_job_state)
        elif job.state == model.Job.states.QUEUED:
            log.debug ("(%s/%s) is still in nesi queued state, adding to the nesi queue" % (job.id,job.get_job_runner_external_id()))
            nesi_job_state.old_state = job_status[1]
            nesi_job_state.running=False
            self.monitor_queue.put(nesi_job_state)

    def shutdown( self ):
        """Attempts to gracefully shut down the monitor thread"""
        log.info( "sending stop signal to worker threads" )
        self.monitor_queue.put( self.STOP_SIGNAL )
        for i in range( len( self.work_threads ) ):
            self.work_queue.put( ( self.STOP_SIGNAL, None ) )
        log.info( "nesi job runner stopped" )

#END
