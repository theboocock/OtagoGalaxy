import os, logging, threading, time, traceback
from datetime import timedelta
from Queue import Queue, Empty

from galaxy import model
from galaxy.jobs.runners import BaseJobRunner

from paste.deploy.converters import asbool
import pkg_resources
import shutil

egg_messages = """

The 'xgrid' runner depends on 'pyxg' which is not installed or not configured properly.
For this job runner to work a mac version of galaxy is required and that the 
Additional Errors may follow:
%s
"""
try:
    pkg_resources.require("PyXg")
    xg= __import__("xg")
except Exception, e:
    raise Exception( egg_messages % str (e))

log = logging.getLogger(__name__)

__all__ = ['XGRIDJobRunner']

#The last twor lines execute the command and retrieve the commands exit code($?) and write
#to a file

job_status= {
    0: "Pending",
    1: "Running",
    2: "Finished",
    3: "Failed",
}


xgrid_template = """#!/bin/sh
GALAXY_LIB="%s"
if [ "$GALAXY_LIB" != "None" ]; then
    if [ -n "$PYTHONPATH" ]; then
        export PYTHONPATH="$GALAXY_LIB:$PYTHONPATH"
    else
        export PYTHONPATH="$GALAXY_LIB"
    fi
fi
%s
cd %s
%s
echo $? > %s"""
class XGRIDJobState( object ):
    def __init__( self ):
        """
        Encapsulates state related to a job that is being run via XGRID and 
        what we need to monitor for each job.
        """
        self.job_wrapper = None
        self.job_id = None
        self.old_state = None
        self.running = False
        self.job_file = None
        self.ofile = None
        self.efile = None
        self.ecfile = None
        self.runner_url = None
        self.check_count=0
        self.stop_job = False

class XGRIDJobRunner(BaseJobRunner):
    """
    Job Runner Backed by a finite pool of worker threads. FIFO scheduling
    """
    STOP_SIGNAL=object()

    def __init__(self, app):
        """Initialize this job runner and start monitor thread"""
        if xg is None:
            raise Exception("XGRIDJobRunner requires pyxg which was not found")
        self.app=app
        self.sa_session=app.model.context
        self.watched=[]
        self.monitor_queue=Queue()
        self.default_xg_server= self.determine_xg_server(self.app.config.default_cluster_job_runner)
        self.default_xg_password = self.determine_xg_password(self.app.config.default_cluster_job_runner)
        self.default_xg_grid=self.determine_xg_grid(self.app.config.default_cluster_job_runner)
        self.xgrid_nfs_mount_location=self.determine_xg_mtp(self.app.config.xgrid_nfs_mount_location)
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
    Xgrid server determination takes the parameter url specified in the 
    default_cluster_runner for now
    
    Format is up to the galaxy wiki standards.

    for now 

        xgrid://<server>/<password>/<grid id>

    """
    def determine_xg_server(self, url, rewrite=False):
        """Determine what XGRID server we are connecting to"""
        url_split=url.split("/")
        server = url_split[2]
        if server =="":
            if not self.default_xg_server:
                self.default_xg_server =None
                log.debug("Set default xgrid server to %s" % self.default_xg_server)
            server = self.default_xg_server
        if server is None:
            raise Exception("Could not find xgrid server")
        if rewrite:
            return (server , "/".join(url_split))
        else: 
            return server
    def determine_xg_mtp(self, mtp_point, rewrite=False):
        """Determine the XG mount point on each of the server
           the reason we need to do hi
        """
        if mtp_point ==None:
            mtp_point=None
        log.debug("Set xgrid mount point to %s" % mtp_point)
        return mtp_point
    def determine_xg_password(self, url): 
        """Determine XGRID password """
        url_split=url.split("/")
        password = url_split[3]
        if password =="":
            if not self.default_xg_password:
                self.default_xg_password =None
                log.debug("Set default xgrid password" )
            password = self.default_xg_password
        if password is None:
            raise Exception("Could not find xgrid password")
        else: 
            return password
    def determine_xg_grid(self, url): 
        """Determine XGRID grid id """
        url_split=url.split("/")
        grid = url_split[4]
        if grid =="":
            if not self.default_xg_grid:
                self.default_xg_grid =None
                log.debug("Set default xgrid grid id" )
            grid = self.default_xg_grid
        if grid is None:
            raise Exception("Could not find xgrid default grid id")
        else: 
            return grid
    """ 
      Function append_nfs_mount_location which replaces 
      the /Users/<user name>/ with the xgrid nfs mount point location

      The reason for this is that xgrid locks you into a sandbox 
      in /tmp or /private/tmp.
      
      To get around this our scripts merely rewrite the path of the job
      to the machine that the xgrid is mounted on.
    """

    def nfs_mount_location(self, job_wrapper,command_line,ecfile):
        exec_dir = os.path.abspath( job_wrapper.working_directory )
        script= xgrid_template %(job_wrapper.galaxy_lib_dir,job_wrapper.get_env_setup_clause(),
        exec_dir,command_line,ecfile)
        job_file ="%s/%s.sh" % (self.app.config.cluster_files_directory, job_wrapper.job_id)
        #TODO
        print self.xgrid_nfs_mount_location
        if self.xgrid_nfs_mount_location is not None:
            orig_path=self.xgrid_nfs_mount_location.split(':')[0]
            new_path=self.xgrid_nfs_mount_location.split(':')[1]
            new_job_file=job_file.replace(orig_path,new_path)
            script= script.replace(orig_path,new_path)
        fh= file(job_file, "w")
        fh.write(script)
        fh.close()
        os.chmod(job_file,0755)
        if self.xgrid_nfs_mount_location is not None:
            job_file=new_job_file
        return new_job_file
    @xg.autorelease
    def monitor(self):
        """
        Watches all jobs currently in the XGRID queue and deals with state changes
        (queued  to running) and job completion
        """
        while 1:
            #take any new jobs and put them on the monitor list.
            try:
                while 1:
                    xgrid_job_state=self.monitor_queue.get_nowait()
                    if xgrid_job_state is self.STOP_SIGNAL:
                        # TODO:This is where any cleanup would occur
                        return
                    self.watched.append(xgrid_job_state)
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
        xg_server= self.determine_xg_server(self.app.config.default_cluster_job_runner)
        xg_password = self.determine_xg_password(self.app.config.default_cluster_job_runner)
        conn = xg.Connection(xg_server, xg_password)
        try:
            cont = xg.Controller(conn)
        except xg.XgridError:
            log.debug("Could not check job status because XGRID connection failed")
        for xgrid_job_state in self.watched:
            job_id=xgrid_job_state.job_id
            galaxy_job_id=xgrid_job_state.job_wrapper.get_id_tag()
            old_state = xgrid_job_state.old_state
            try: 
                job =cont.job(job_id)
            except:
                log.debug("Could not check job status becaues XGRID connection failed")
            status=job.getStatus()
            if status != old_state:          
                log.debug("(%s/%s) XGRID Jobs state changed from %s to %s" % (galaxy_job_id, job_id,old_state,status))
            if status == "Running" and not xgrid_job_state.running:
                xgrid_job_state.old_state=job_status[1]
                xgrid_job_state.running=True
                xgrid_job_state.job_wrapper.change_state(model.Job.states.RUNNING)
                new_watched.append(xgrid_job_state)
            elif status == "Running" and xgrid_job_state.running:
                new_watched.append(xgrid_job_state)
            elif status == "Failed" or status == "Fail":
                xgrid_job_state.old_state=job_status[3]
                self.work_queue.put(('finish', xgrid_job_state))
            elif status == "Pending":
                xgrid_job_state.old_state=job_status[0]
                new_watched.append(xgrid_job_state)
            elif status == "Finished":
                xgrid_job_state.old_state=job_status[2]
                self.work_queue.put(('finish',xgrid_job_state))

        self.watched= new_watched

    def queue_job(self, job_wrapper):
        """Queue a xgrid job"""
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
            log.debug("Job %s deleted by user before it entered the XGRID queue" % job_wrapper.job_id)
            if self.app.config.cleanup_job in ("always", "onsuccess"):
                job_wrapper.cleanup()
            return
        runner_url=job_wrapper.get_job_runner_url()
        xgrid_server=self.determine_xg_server(runner_url)
        xgrid_password=self.determine_xg_password(runner_url)
        xgrid_grid_id=self.determine_xg_grid(runner_url)
        conn = xg.Connection(hostname=xgrid_server,password=xgrid_password)
        try:
            cont = xg.Controller(conn)
        except: 
            job_wrapper.fail("Unable to queue job for execution, Resubmitting the job may succeed.")
            log.error("Connection to the Xgrid server for submission failed")
        ecfile = "%s/%s.ec" % (self.app.config.cluster_files_directory, job_wrapper.job_id)
        ofile  = "%s/%s.o" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        efile = "%s/%s.e" %(self.app.config.cluster_files_directory,job_wrapper.job_id)
        #Check if job has been deleted before we submit the job
        #
        
        exec_dir = os.path.abspath( job_wrapper.working_directory )
        job_file = self.nfs_mount_location(job_wrapper,command_line,ecfile)
        if job_wrapper.get_state() == model.Job.states.DELETED:
            log.debug("Job %s deleted by user before it entered the XGRID queue" % job_wrapper.job_id)
            if self.app.config.cleanup_job in ("always", "onsuccess"):
                job_wrapper.cleanup((ofile,efile,ecfile,jobfile))
            return
        #submit
        galaxy_job_id = job_wrapper.get_id_tag()
        log.debug("(%s) submitting file %s" % (galaxy_job_id, job_file))
        log.debug("(%s) command is: %s" % (galaxy_job_id, command_line))
               
        #Submit the job to xgrid
        try: 
            job_id=cont.submit(cmd=job_file,gridID=xgrid_grid_id)
        except:
            job_wrapper.fail("Unable to queue job for execution, Resubmitting job may succeed")
            log.error("Submission of job to the Xgrid server failed")
        #Maybe Unnecessary error checking
        if not job_id:
            job_wrapper.fail("Unable to queue job for execution, Resubmitting job may succeed.")
            log.error("Submission of job to the Xgrid server failed")
            return
       #store runner information for tracking if Galaxy restarts.
        job_wrapper.set_runner(runner_url, job_id.jobID)
        #Store XGRID related state information for job.
        xgrid_job_state=XGRIDJobState()
        xgrid_job_state.job_wrapper = job_wrapper
        xgrid_job_state.job_id= job_id.jobID
        xgrid_job_state.ecfile=ecfile
        xgrid_job_state.job_file=job_file
        xgrid_job_state.old_state= job_status[0]
        xgrid_job_state.running=False
        xgrid_job_state.runner_url=runner_url 
        xgrid_job_state.ofile = ofile
        xgrid_job_state.efile = efile
        #Add to our queue of jobs to monitor
        self.monitor_queue.put(xgrid_job_state)

    @xg.autorelease
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
                log.exception( "(%s) Uncaught exception %sing job" % ( getattr( obj, 'job_id', None ), op ) )
    
    def put(self, job_wrapper):
        """Add a job to the queue(by job identifier)"""
        #change the queued state before handing to workthread so the runner won't pick it up again
        job_wrapper.change_state(model.Job.states.QUEUED)
        self.work_queue.put(('queue',job_wrapper))

    def stop_job(self,job):
        """Attempts to remove a job from the XGRID queue"""
        job_tag = ("(%s/%s)" % (job.get_id_tag(),job.get_job_runner_external_id())
        log.debug("%s Stopping xgrid job" % job_tag)
        xgrid_server=self.determine_xg_server(runner_url)
        xgrid_password=self.determine_xg_password(runner_url)
        xgrid_grid_id=self.determine_xg_grid(runner_url)
        conn = xg.Connection(hostname=xgrid_server,password=xgrid_password)
        try:
            cont = xg.Controller(conn)
        except:
            log.debug("Could not stop job becaues XGRID connection failed")
        job=cont.job(xgrid_job_state.job_id)
	try:
	   	job.stop()
	except:
	 	log.debug("Could not stop xgrid job")

    def finish_job(self, xgrid_job_state):
        """Finishes a job sent to xgrid"""
        ecfile = xgrid_job_state.ecfile 
        ofile = xgrid_job_state.ofile
        efile = xgrid_job_state.efile
        job_file = xgrid_job_state.job_file      
        runner_url=xgrid_job_state.job_wrapper.get_job_runner_url()
        xgrid_server=self.determine_xg_server(runner_url)
        xgrid_password=self.determine_xg_password(runner_url)
        xgrid_grid_id=self.determine_xg_grid(runner_url)
        conn = xg.Connection(hostname=xgrid_server,password=xgrid_password)
        try:
            cont = xg.Controller(conn)
        except:
            log.debug("Could not check job status becaues XGRID connection failed")
        job =cont.job(xgrid_job_state.job_id)
        job.results(stdout=ofile,stderr=efile,block=0)
        
        try:
            efh=file(xgrid_job_state.efile,"r")
            ofh=file(xgrid_job_state.ofile, "r")
            stdout = ofh.read(32768)
            stderr = efh.read(32768)
        except:
            log.debug("Could not open stdout/stderr files")
        try:
            ecfh = file(ecfile, "r")
            exit_code_str= ecfh.read(32)
        except:
            stdout = ''
            stderr = 'Job output not returned by XGRID: The job was manually dequeued or there was a cluster error'
            exit_code_str=""
        try:
            exit_code = int (exit_code_str)
        except:
            log.warning("Exit code" + exit_code_str + " was invalid, Using 0." )
            exit_code = 0
        try:
            xgrid_job_state.job_wrapper.finish(stdout, stderr, exit_code)
        except:
            log.exception("Job Wrapper finish method failed")
            xgrid_job_state.job_wrapper.fail("Unable to finish job", exception=True)
        if self.app.config.cleanup_job == "always" or ( not stderr and self.app.config.cleanup_job == "onsuccess" ):
            log.debug("KEEP THE FILES")
            #self.cleanup((ecfile,job_file,ofile,efile))
    
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
        xgrid_job_state=XGridJobState()
        xgrid_job_state.ofile= "%s/%s.o" % (self.app.config.cluster_files_directory, job.id)
        xgrid_job_state.efile= "%s/%s.e" % (self.app.config.cluster_files_directory, job.id)
        xgrid_job_state.ecfile "%s/%s.ec" % (self.app.config.cluster_files_directory, job.id)
        xgrid_job_state.job_file= "%s/%s.sh" % (self.app.config.cluster_files_directory,job.id)
        xgrid_job_state.job_id=str(job_id)
        xgrid_job_state.runner_url=job_wrapper.get_job_runner_url()
        xgrid_job_state.job_wrapper= job_wrapper
        if job.state == model.Job.states.RUNNING:
            log.debug ("(%s/%s) is still running, adding to the xgrid queue" %(job.id,job.get_job_runner_external_id()))
            xgrid_job_state.old_state=xgrid_job_state[2]
            xgrid_job_state.running = True
            self.monitor_queue.put(xgrid_job_state)
        elif job.state == model.job.states.QUEUED:
            log.debug ("(%s/%s) is still in XGRID queued state, adding to the XGRID queue" % (job.id,job.get_job_runner_external_id()))
            xgrid_job_state.old_state = job_status[0]
            xgrid_job_state.running=False
            self.monitor_queue.put(xgrid_job_state)

    def shutdown( self ):
        """Attempts to gracefully shut down the monitor thread"""
        log.info( "sending stop signal to worker threads" )
        self.monitor_queue.put( self.STOP_SIGNAL )
        for i in range( len( self.work_threads ) ):
            self.work_queue.put( ( self.STOP_SIGNAL, None ) )
        log.info( "xgrid job runner stopped" )
