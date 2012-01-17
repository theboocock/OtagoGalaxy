dbsnp.pl

A Perl script for downloading and implementing a local copy of the
dbSNP relational database.

INSTALLATION

    * System requirements
    
        > Unix operating system
        > MySQL installed with the 'mysql' & 'mysqldump' commands available from the Unix command line
        > The programs "gunzip" and "gzip" are available from the command line
        
    * Required Perl modules (see http://www.cpan.org)

        > Net::FTP
        > DBI
        > LWP::UserAgent
        > Net::Domain
        > Getopt::Long
        > File::Basename
        > Text::Wrap
        > File::stat

        These modules can be found at http://www.cpan.org. For general
        installation instructions see http://www.cpan.org/modules/INSTALL.html.
    
USAGE

Execute the script from the command line using the format

    * dbsnp.pl [command] [options]

For a list of commands and options use ./dbsnp.pl --help.
 

USING THE OPTIONS FILE WE PROVIDE

We have provided the options file and human_131_test.opt. It has been configured
to use dbsnp.pl with the human data from dbSNP build 131. It will only process the
first 1000 rows of each dbSNP table, which is useful for testing the script on
your system. You must edit this file to specifiy some options, such as the
directory where downloaded dbSNP files are saved and information about your
MySQL database. The 1000 row limit can be changed by modifying or removing the
max-rows option in the options file.

Use can run dbsnp.pl with these options as follows:

    dbsnp.pl [command] --options-file=human_131.opt

SPECIFYING THE MYSQL PASSWORD

The password for the MySQL database can be provided on the command line or in a file.  Using
a file is safer because the command line could be viewed in the Unix process list.  The options
file human_131.opt assume the password file is named 'passwd' and resides in current working
directory ('.' in Linux). Caution should be used in setting the read permissions for this file.

USING THE PROVIDED INPUT FILES - SPECIFYING WHICH dbSNP TABLES TO DOWNLOAD

    * tables_to_load.txt: a list of tables we commonly use.  This file is specified
      by the --tables-to-download and --tables-to-load options.  It has been configured
      in the human_131.opt options file.  This file allows for certain kinds of formatting
      like blank spaces and '#' comment characters.
      
    * local_tables.sql: MySQL code that creates the local tables described in the manuscript [*** REF]


OUTPUT FILES AND DIRECTORIES

    These are used internally by dbsnp.pl and do not need to be viewed or modified by the user.
    Words prefixed by "--" refer to dbsnp.pl options.  For example --organism will be human_9606
    when using human data.
    
    * --download-dir/shared: shared schemas and data files
    
    * --download-dir/--organism: organism-specific schemas and data files
    
    * dbsnp_table_list.txt: list of dbSNP tables, their type (SHARED/ORGANISM) and
      the corresponding schema file
      
    * dbsnp_consolidated_tables.txt: all MSSQL schema code from dbSNP schema files
    
    * dbsnp_consolidated_tables_mysql.txt: result of conversion to MySQL
    
    * Files are download from dbSNP FTP server to shared and organism-specific subdirectories
      of --download-dir
    * A list tables, and their 

THE HELP PAGE

This is the output from dbsnp.pl --help showing documentation on commands
and options.

==
###################################################################
dbsnp.pl
Wed Apr  7 12:44:36 CDT 2010
###################################################################


USAGE: dbsnp.pl [command] [options]

Commands

  getorg        Attempt to determine the taxonomy ID and dbSNP
                database name for a specified organism.  Example:
                getorg --organism=mouse retrieves 'mouse_10090' and
                'mouse_spretus_10096'.
              
  getbuild      Attempt to determine the current dbSNP build
                (example: 131) and genome versions. Examples of
                genome versions: 37_1 - use this for the option
                --genome when running the load --load-script
                command. Also: GRCh37 - use this for the option
                --genome-long.
                
  download      Download dbSNP data and schemas files from FTP server
                and convert dbSNP MSSQL schemas to MySQL
                
  load          Load dbSNP data files into a local MySQL database

  runscript     Run the specified MySQL script, and substitute the
                variables $build, $genome, $genome_long and $max_rows
                with the corresponding options from the command line. We
                provide the script local_tables_human.sql.
  
  log           Create and/or update the MySQL table '_loc_table_log'
                which maintains summary information about the dbSNP
                tables.
  
Parameters (*=required, may be abbreviated to uniqueness):

  --build[=build]               Build of dbSNP (default = 131). Try
                                using the command 'getbuild' to determine the
                                current version of this.
  --check-data-dictionary       Checks that tables are in dbSNP's online data
                                dictionary (the log command).
  --database[=database]         Name of MySQL database
  --determine-build             Attempt to look up current build and genome for given organism
  --download-all-tables         Download data for all dbSNP tables that appear
                                in the schema files (default = NO)
  --download-schemas            Download dbSNP schemas (default = NO)
  --download-dir[=dir]          Local download directory (default = dbsnp_downloads)
  --email-address[=address]     For anonymous login to dbSNP FTP site
  --engine[=engine]             MySQL engine (default = MyISAM)
  --genome[=value]              Genome build in N_M format (example: 37_1).  Try
                                using the command 'getbuild' to determine the current
                                version of this.
  --genome_long[=value]         Longer format of genome build. Example: GRCh37.
                                Used in tables ContigInfo and SNPMapInfo. Try
                                using the command 'getbuild' to determine the current
                                version of this.
  --help                        Display this help message and quit
  -H, --host[=host]             Host (default = localhost)
  --init-table-log              Initialize the table _loc_table_log (the log command)
  --max-rows[=value]            Maximum number of rows to load into MySQL database
  --only-create-tables          Only create MySQL tables, do not load data (default = NO)
  --options-file[=file]         Specifiy a file containing command line options.  The leading
                                "--" should not be used.  Options are specified in the format
                                "option=value" or just "option".  Whitespace is ignored, and
                                comments may be inserted after a leading '#'
  --organism[=organism]*        Organism.  Use the <name>_<taxonomy ID> notation. Example: human_9606.
                                Use the 'getorg' command to look this up.
  -P, --password[=password]     MySQL password
  --password-file[=file]        File containing MySQL password
  --print-options               Print the complete list of options at the start of the script
  --script[=file]               Run the specified MySQL script (the load command). See
                                the option --update-script
  --tables-to-download[=list]   Comma-separated list of dbSNP table names that
                                will be downloaded from the dbSNP FTP server
  --tables-to-download-file[=file]
                                A single-column file specifying the tables-to-download
  --tables-to-load[=list]       Comma-separated list of dbSNP table names that
                                will be loaded into MySQL database
  --tables-to-load-file[=file]  A single-column file specifying tables-to-load
  --use-all-tables              Load all dbSNP tables into the MySQL database
  -U, --user[=username]         MySQL username
==

