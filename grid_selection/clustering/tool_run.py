"""
    Tool run for galaxy clustering interfacte
    Date: January 2013
    Author: James Boocock
"""

""" This class prepares everything related to a tool run in the galaxy clustering interface """
import os
import sys
import logging

import util

log =logging.getLogger(__name__)

class ToolRun(object):
    """ Tool run class contains functions to perform the setup to run each individual tool"""

    def __init__(self,app, job_wrapper, grids,ui_reader):
        self.app = app
        self.ui_reader = ui_reader
        self.job_wrapper = job_wrapper
        #Just to start get something working so we can see if this works on the nesi server
        self.job_id = self.job_wrapper.get_job().tool_id
        log.debug(self.job_id)
        #Set to none for the local runner#  
        self.grid_to_run_on = self.ui_reader.get_grid(self.job_id)
        log.debug(self.grid_to_run_on)
        self.grids = grids
        log.debug(grids)
        self.datatypes = [] 
        # need to get the grid from the ui that the user has selected #
        # We are running on local or lwr if grid is none
        job = job_wrapper.get_job()
        #Do parrarelism stuff so set the runner to tasks.
        #Check to see whether the user defined any split options
        #Check to make sure we have enabled tasked jobs
        if self.ui_reader.is_parralel(self.job_id) and not self.app.config.use_tasked_jobs:
            raise Exception, "Use tasked jobs needs to be set to true in your universe config to use parralelism options"
        result = self.ui_reader.create_task(self.job_id) 
        if result:
            """ Do all the parralelism here """
            log.debug("Job Running in parralel")
            #Requires tasks be enabled in galaxy otherwise the job dispatcher wont start#
            self.runner_name="tasks"
             
            # this will create all the tasks needed to run the galaxy job #
            # setting the runner to tasks the tasks will be run from galaxy and come back through here to get 
            # sent to the runner each of the tasks where set to go to #
            # tasks are created so galaxy can unset parralelism and all future tasks will be sent to what
            # they are meant to be set to 
             
            #unset parrellel after
        #Final setup of job sends it to the task runner.
        else:
        #try: 
            self.runner_name= self.grid_to_run_on.get_grid_runner() 
        #Do grid preparation here#
            log.debug(self.grid_to_run_on)
            self.job_wrapper.prepare()
            log.debug("tool_run.py line:61" + str(job_wrapper.get_input_fnames()))
            self.command_line =job_wrapper.get_command_line()
            log.debug(self.runner_name + " " + self.command_line)
            # Ensure we dont try and prepare paths for jobs that are just running locally
            if(self.grid_to_run_on != self.grids['local']):
                self.fake_galaxy_dir = self.grid_to_run_on.prepare_paths(job_wrapper.get_job().tool_id)
                job_wrapper.command_line= self.fake_galaxy_dir + " " +job_wrapper.command_line
            #grid.prepare_datatypes(job_wrapper)
        #except:
            #log.debug("Could not get a grid runner for grid: " + str(self.grid_to_run_on))
    

    def get_grid_runners(self):
        runners = []
        for grid in self.grids:
            runners.append(self.grids[grid].get_grid_runner())
        return runners
    def get_grids(self):
        for grid in self.grids:
            return grid
    def get_grid_from_ui(self):
        """Get the selected grid to run the job from the ui for this job"""
        
        #for grid in self.grids:
         #   return self.grids[grid]
        return "local"

    def get_tool_options(self):
        return 1


    """ Accessors """

    def get_runner_name(self):
        return self.runner_name
    
    def build_command_line( self, job_wrapper, include_metadata=False, include_work_dir_outputs=True ):
        """
        Compose the sequence of commands necessary to execute a job. This will
        currently include:

            - environment settings corresponding to any requirement tags
            - preparing input files
            - command line taken from job wrapper
            - commands to set metadata (if include_metadata is True)
        """

        commands = job_wrapper.get_command_line()
        # All job runners currently handle this case which should never
        # occur
        if not commands:
            return None
        # Prepend version string
        if job_wrapper.version_string_cmd:
            commands = "%s &> %s; " % ( job_wrapper.version_string_cmd, job_wrapper.get_version_string_path() ) + commands
        # prepend getting input files (if defined)
        if hasattr(job_wrapper, 'prepare_input_files_cmds') and job_wrapper.prepare_input_files_cmds is not None:
            commands = "; ".join( job_wrapper.prepare_input_files_cmds + [ commands ] ) 
        # Prepend dependency injection
        if job_wrapper.dependency_shell_commands:
            commands = "; ".join( job_wrapper.dependency_shell_commands + [ commands ] ) 

        # Append commands to copy job outputs based on from_work_dir attribute.
        if include_work_dir_outputs:
            work_dir_outputs = self.get_work_dir_outputs( job_wrapper )
            if work_dir_outputs:
                commands += "; " + "; ".join( [ "if [ -f %s ] ; then cp %s %s ; fi" % 
                    ( source_file, source_file, destination ) for ( source_file, destination ) in work_dir_outputs ] )

        # Append metadata setting commands, we don't want to overwrite metadata
        # that was copied over in init_meta(), as per established behavior
        if include_metadata and self.app.config.set_metadata_externally:
            commands += "; cd %s; " % os.path.abspath( os.getcwd() )
            commands += job_wrapper.setup_external_metadata( 
                            exec_dir = os.path.abspath( os.getcwd() ),
                            tmp_dir = job_wrapper.working_directory,
                            dataset_files_path = self.app.model.Dataset.file_path,
                            output_fnames = job_wrapper.get_output_fnames(),
                            set_extension = False,
                            kwds = { 'overwrite' : False } ) 
        return commands
