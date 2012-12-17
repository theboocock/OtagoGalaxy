import os, logging, threading, time, traceback
from datetime import timedelta
from Queue import Queue, Empty

from galaxy import model
from galaxy.jobs.runners import BaseJobRunner

from paste.deploy.converters import asbool
import pkg_resources
import shutil

from subprocess import call

egg_messages = """

The 'nesi' runner depends on 'grython' which is not installed or not configured properly.
For this job runner to work a mac version of galaxy is required and that the 
Additional Errors may follow:
%s
"""
try:
except Exception, e:
    raise Exception( egg_messages % str (e))

log = logging.getLogger(__name__)

__all__ = ['NesiJobRunner']

# possible job statuses
job_status= {
    0: "Done",
    1: "Pending",
    2: "Failed",
    3: "Broken/Not found",
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
        self.job_file = None
        self.ofile = None
        self.efile = None
        self.ecfile = None
        self.runner_url = None
        self.check_count=0
        self.stop_job = False

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
        self.default_nesi_grid=self.determine_nesi_runner(self.app.config.default_cluster_job_runner)
        self.default_nesi_grid=self.determine_nesi_server(self.app.config.default_cluster_job_runner)
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

    for now 

        runner://<server>
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
        if nesi_group == "" or is None:
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
                        # TODO:This is where any cleanup would occur
                        return
                    self.watched.append(nesi_job_state)
            except Empty:
                pass 

            #Iterate over the list of watched jobs and check state.
            try:
                self.check_watched_items()
            except:
                log.exception("Uncaught exception checking jobs")

            #sleep a bit before the next state is checked
            time.sleep(10)

    def check_watched_items(self):
        """Called by the monitor thread to look at each of the jobs and deal 
            with state changes"""
        new_watched=[]
        nesi_server= self.determine_nesi_server(self.app.config.default_cluster_job_runner)
        nesi_runner= self.determine_nesi_runner(self.app.config.default_cluster_job_runner)
        
        try:
            # TODO: pending RE from markus
            # write each job result to a file, then read that file and check them all.. good times
        except :
            log.debug("Could not check job status because Nesi connection failed")
        for nesi_job_state in self.watched:
            job_name = nesi_job_state.job_name
            galaxy_job_id = nesi_job_state.job_wrapper.get_id_tag()
            old_state = nesi_job_state.old_state
            try: 
                #TODO parsing of file will need to be done RE above 
                with open("nesi_job_states", "r") as njs:
                    status = ""
                    for line in njs:
                        line = line.split(":")
                        state_jobname = line[0]
                        if state_jobname == job_name:
                            status = line[1]

                    if status == "":
                        log.debug("Could not find job in NeSI queue that matched: ", job_name
            except:
                log.exception("Could not access jobs to check job status.")

            print status
            if status != old_state:          
                log.debug("(%s/%s) NeSI Jobs state changed from %s to %s" % (galaxy_job_id, job_name,old_state,status))
            if status == "Active" and not nesi_job_state.running:
                nesi_job_state.running=True
                nesi_job_state.job_wrapper.change_state(model.Job.states.RUNNING)
                new_watched.append(nesi_job_state)
            elif status == "Active" and nesi_job_state.running:
                new_watched.append(nesi_job_state)
            elif status == "Failed":
                self.work_queue.put(('finish', nesi_job_state))
            elif status == "Broken/Not Found":
                new_watched.append(nesi_job_state)
            elif status == "Successful":
                self.work_queue.put(('finish',nesi_job_state))

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
        nesi_runner=self.determine_nesi_runner(runner_url)
        nesi_server=self.determine_nesi_server(runner_url)
        ecfile = "%s/%s.ec" % (self.app.config.cluster_files_directory, job_wrapper.job_id)
        ofile  = "%s/%s.o" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        efile = "%s/%s.e" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        exec_dir = os.path.abspath( job_wrapper.working_directory )

        #TODO stip file paths here. to make it relative path for nesi
        if job_wrapper.get_state() == model.Job.states.DELETED:
            log.debug("Job %s deleted by user before it entered the Nesi queue" % job_wrapper.job_id)
            if self.app.config.cleanup_job in ("always", "onsuccess"):
                job_wrapper.cleanup((ofile,efile,ecfile,jobfile))
            return

        #submit
        galaxy_job_id = job_wrapper.get_id_tag()
        log.debug("(%s) Submitting: %s" % (galaxy_job_id, command_line))
               
        #Submit the job to nesi
        rc = call(["./submit_job.py", nesi_runner + ":" + nesi_server, self.nesi_group, galaxy_job_id, command_line])

        # TODO needs to be cleaned up
        with open("nesi_job_name.tmp", 'r') as njn:
            nesi_job_name = njn.readline()     

        #TODO have more verbose error codes / checking
        if rc != 0:
            job_wrapper.fail("Unable to queue job for execution.")
            log.error("Submission of job to the submit server failed.")
            return

        # store runner information for tracking if Galaxy restarts.
        job_wrapper.set_runner(runner_url, job_id.job_name)
        # Store nesi related state information for job.
        nesi_job_state=NesiJobState()
        nesi_job_state.job_wrapper = job_wrapper
        nesi_job_state.job_name= nesi_job_name
        nesi_job_state.ecfile=ecfile
        nesi_job_state.job_file=job_file
        nesi_job_state.old_state= job_status[0]
        nesi_job_state.running=False
        nesi_job_state.runner_url=runner_url 
        nesi_job_state.ofile = ofile
        nesi_job_state.efile = efile
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

    # TODO figure out how job helps us get our job_name
    def stop_job(self,job):
        """Attempts to remove a job from the Nesi queue"""

        rc = call(["./stop_job.py", nesi_runner + ":" + nesi_server, self.nesi_group, nesi_job_name])

        #TODO have more verbose error codes / checking
        if rc != 0:
            job_wrapper.fail("Unable to remove job from execution.")
            log.error("Removal of job from the NeSI queue failed.")
            return

    def finish_job(self, nesi_job_state):
        """Finishes a job sent to nesi"""
        ecfile = nesi_job_state.ecfile 
        ofile = nesi_job_state.ofile
        efile = nesi_job_state.efile
        runner_url=nesi_job_state.job_wrapper.get_job_runner_url()
        nesi_server=self.determine_nesi_server(runner_url)
        nesi_runner=self.determine_nesi_runner(runner_url)
        nesi_job_name = nesi_job_state.job_name
        
        # get results
        rc = call(["./get_results.py", ofile, efile, ecfile, nesi_job_name])
        
        try:
            efh=file(nesi_job_state.efile,"r")
            ofh=file(nesi_job_state.ofile, "r")
            stdout = ofh.read(32768)
            stderr = efh.read(32768)
            print stderr,stdout
        except:
            log.debug("Could not open stdout/stderr files")
        try:
            ecfh = file(ecfile, "r")
            exit_code_str= ecfh.read(32)
        except:
            stdout = ''
            stderr = 'Job output not returned by Nesi: The job was manually dequeued or there was a cluster error'
            exit_code_str=""
        try:
            exit_code = int (exit_code_str)
        except:
            log.warning("Exit code" + exit_code_str + " was invalid, Using 0." )
            exit_code = 0
        try:
            nesi_job_state.job_wrapper.finish(stdout, stderr, exit_code)
        except:
            log.exception("Job Wrapper finish method failed")
            nesi_job_state.job_wrapper.fail("Unable to finish job", exception=True)
        if self.app.config.cleanup_job == "always" or ( not stderr and self.app.config.cleanup_job == "onsuccess" ):
            # FIXME --- keep the files now for debugging purposes
            #self.cleanup((ecfile,job_file,ofile,efile))
    
    def cleanup( self, files ):
        for file in files:
            try:
                os.unlink( file )
            except Exception, e:
                log.warning( "Unable to cleanup: %s" % str( e ) )

    #TODO -- recover a nesi job if galaxy dies in between
    def recover (self, job,job_wrapper):
        pass

    def shutdown( self ):
        """Attempts to gracefully shut down the monitor thread"""
        log.info( "sending stop signal to worker threads" )
        self.monitor_queue.put( self.STOP_SIGNAL )
        for i in range( len( self.work_threads ) ):
            self.work_queue.put( ( self.STOP_SIGNAL, None ) )
        log.info( "nesi job runner stopped" )

#END