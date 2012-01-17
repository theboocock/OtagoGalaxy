#!/usr/bin/perl

=head1 NAME

    dbsnp.pl - download data and MSSQL schema files from dbSNP,
	       convert to MySQL and load into a specified MySQL database

=cut

=head1 USAGE

    ./dbsnp.pl [command] [options]
    
    Use ./dbsnp.pl --help for a list of commands

=cut

use strict;
use warnings qw(FATAL all);
use Getopt::Long;    # Get the command line options
no strict 'refs';    # Be less restrictive so we can use a string as a subroutine reference

# LOCAL MODULES

use Download;
use LoadTables;
use TableLog;

# SUBROUTINE DECLARATIONS

sub download;
sub print_usage;
sub load;
sub runscript;
sub log;
sub print_options;
sub getbuild;
sub getorg;
sub ReadOptionsFile;
sub process_options;

#
# GLOBAL VARIABLES
#

my $user          = '';
my $password      = '';
my $password_file = '';
my $host          = '';
my $db            = '';

my $organism    = '';       # EG: human_9606
my $genome      = '';       # EG: 37_1
my $genome_long = '';       # EG: GRCh37
my $build       = undef;    # EG: 131

my $download_dir = '';      # Stores all downloaded schems and data from dbSNP

my $tables_to_download      = '';    # Comma-separated list of tables to load
my $tables_to_download_file = '';
my $download_all_tables     = 0;
my $download_schemas        = 0;
my $determine_build         = 0;
my $script                  = '';
my $email_address           = '';
my $options_file;                    # = 'dbsnp.opt';

my $tables_to_load_file = '';        # Single colulmn list of tables to load into MySQL database
my $tables_to_load      = '';        # Comma-separated list of tables to load.
				     # If $tables_to_load_file is defined then this is ignored.
my $use_all_tables      = 0;         # Load all tables into MySQL database
my @tables_to_load;                  # Derived from $tables_to_load
my $max_rows              = undef;
my $only_create_tables    = 0;
my $check_data_dictionary = 0;      # Whether to check if tables are documented in dbSNP's online DD
my $engine = 'MyISAM';              # Engine to use for MySQL tables

my $init_table_log  = 0;
my $make_excel_file = 0;
my $print_options   = 0;            # Whether to print complete list of options at the start

# Dump options

my $dump_dir = "dump_dir";
my $dump_mysql_options = "--disable-keys";
my $dump_db = 0;
my $dump_tables = 0;

# Subversion revision #

my $svn_revision_text = '$Rev: 661 $'; # Using subversion auto-substitute feature
my $svn_revision;

if ($svn_revision_text =~ /(\d+)/) {
    $svn_revision = $1;
} else {
    $svn_revision = '?';
}

#
# MAIN
#

$| = 1;
my $date = `date`;
chomp($date);
print <<EOF;

###################################################################
dbsnp.pl
$date
Subversion revision $svn_revision
###################################################################

EOF

# Get command from user
my @commands = qw(getorg getbuild download load runscript dump log);
my $command  = $ARGV[0];

unless ( defined $command ) {
    print "\nERROR: missing command\n";
    print_usage;
}

if ( !( grep /^$command$/, @commands ) && ( $command ne '--help' ) ) {
    print "\nERROR: unknown command \"$command\"\n";
    print_usage;
}

process_options;    # Process command line arguments
readOptionsFile($options_file) if $options_file;    # Read options from a file

# Set up FTP directory - $ftp_dir is passed as an option to the different modules
my $ftp_dir = {
    DATA => {
	SHARED   => "/snp/database/shared_data/",
	ORGANISM => "/snp/database/organism_data/$organism"
    },
    SCHEMA => {
	SHARED   => "/snp/database/shared_schema/",
	ORGANISM => "/snp/database/organism_schema/$organism"
    }
};

print_options if $print_options;

mkdir $download_dir unless -e $download_dir;

# Set $password if $password_file is given
if ($password_file) {
    print STDOUT "Reading MySQL password from the file $password_file\n";
    open PFILE, "<$password_file"
      or die "\nERROR: opening the password file $password_file: $!";
    $password = <PFILE>;
    chomp($password);
    close PFILE;
}

# Run subroutine corresponding to command
&$command;

print "Goodbye\n";
exit 0;

#
# SUBROUTINES
#

sub getorg {
    Download::download_tables(
	organism      => $organism,
	ftp_dir       => $ftp_dir,
	download_dir  => $download_dir,
	email_address => $email_address,
	user          => $user,
	password      => $password,
	host          => $host,
	db            => $db,
	determine_org => 1,
	engine        => $engine
    );
}

sub getbuild {
    Download::download_tables(
	organism        => $organism,
	ftp_dir         => $ftp_dir,
	download_dir    => $download_dir,
	email_address   => $email_address,
	user            => $user,
	password        => $password,
	host            => $host,
	db              => $db,
	determine_build => 1,
	engine          => $engine
    );
}

sub download {
    Download::download_tables(
	organism                => $organism,
	build                   => $build,
	genome                  => $genome,
	ftp_dir                 => $ftp_dir,
	download_dir            => $download_dir,
	tables_to_download      => $tables_to_download,
	tables_to_download_file => $tables_to_download_file,
	download_all_tables     => $download_all_tables,
	download_schemas        => $download_schemas,          # If yes download them all
	email_address           => $email_address,
	determine_build         => $determine_build,
	engine                  => $engine
    );
}

sub load {
    LoadTables::load_data(
	user                => $user,
	password            => $password,
	host                => $host,
	db                  => $db,
	build               => $build,
	organism            => $organism,
	genome              => $genome,
	genome_long         => $genome_long,
	download_dir        => $download_dir,
	tables_to_load      => $tables_to_load,
	tables_to_load_file => $tables_to_load_file,
	use_all_tables      => $use_all_tables,
	max_rows            => $max_rows,
	only_create_tables  => $only_create_tables,
    );
}

sub runscript {
    LoadTables::load_script(
	load_script   => 1,
	update_script => 1,
	script        => $script,
	user          => $user,
	password      => $password,
	host          => $host,
	db            => $db,
	build         => $build,
	organism      => $organism,
	genome        => $genome,
	genome_long   => $genome_long,
	download_dir  => $download_dir,
	max_rows      => $max_rows
    );
}

sub log {
    TableLog::table_log(
	user                  => $user,
	password              => $password,
	host                  => $host,
	db                    => $db,
	engine                => $engine,
	ftp_dir               => $ftp_dir,
	download_dir          => $download_dir,
	organism              => $organism,
	init_table_log        => $init_table_log,
	check_data_dictionary => $check_data_dictionary,
	make_excel_file       => $make_excel_file
    );
}

sub dump {
    LoadTables::dump(
	user              => $user,
	password          => $password,
	host              => $host,
	db                => $db,
	dump_db           => $dump_db,
	dump_tables       => $dump_tables,
	dump_dir          => $dump_dir,
	dump_mysql_options => $dump_mysql_options,
	max_rows          => $max_rows
    );
}

# Print the usage for this script and exit
sub print_usage() {
    print <<EOF;

USAGE: dbsnp.pl [command] [options]

Commands

  getorg			Attempt to determine the taxonomy ID and dbSNP
				database name for a specified organism.  Example:
				getorg --organism=mouse retrieves 'mouse_10090' and
				'mouse_spretus_10096'.
				
  getbuild                      Attempt to determine the current dbSNP build
				(example: 131) and genome versions. Examples of
				genome versions: 37_1 - use this for the option
				--genome when running the load --load-script
				command. Also: GRCh37 - use this for the option
				--genome-long.
				
  download                      Download dbSNP data and schemas files from FTP server
				and convert dbSNP MSSQL schemas to MySQL
				
  load                          Load dbSNP data files into a local MySQL database

  runscript			Run the specified MySQL script, and substitute the
				variables \$build, \$genome, \$genome_long and \$max_rows
				with the corresponding options from the command line. We
				provide the script local_tables_human.sql.

  dump                          Dump mysql tables from dbSNP MySQL database
				using the command mysqldump to the directory
                                --dump-dir with options --dump-mysql-options.
				If --dump-db is specified then entire database is dumped, if
				--dump-tables is specified then tables are dumped individually. Both
				options may be used simultaneously, at least one must be specified.
				Dumped files are compressed with gzip. They may be loaded back into
				MySQL using the command gunzip --to-stdout <file>.gz | mysql <database>.
				
  log                           Create and/or update the MySQL table '_loc_table_log'
				which maintains summary information about the dbSNP
				tables.
  
Parameters (*=required, may be abbreviated to uniqueness):

  --build[=build]               Build of dbSNP (default = 131). Try
				using the command 'getbuild' to determine the
				current version of this.
  --check-data-dictionary       Checks that tables are in dbSNP's
				online data dictionary (the log command). Checks
				all known tables, not just downloaded tables. 
  --database[=database]         Name of MySQL database
  --determine-build             Attempt to look up current build and genome for given organism
  --download-all-tables         Download data for all dbSNP tables that appear
				in the schema files (default = NO)
  --download-schemas            Download dbSNP schemas (default = NO)
  --download-dir[=dir]          Local download directory (default = dbsnp_downloads)
  --dump-db                     If set then dump entire database when dump command is used
  --dump-dir[=dir]		Where to save dumped files for dump command
  --dump-mysq-options		Options passed to mysqldump for dump command
  --dump-tables                 If set then dump individual tables when dump command is used
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
  --options-file[=file]		Specifiy a file containing command line options.  The leading
				"--" should not be used.  Options are specified in the format
				"option=value" or just "option".  Whitespace is ignored, and
				comments may be inserted after a leading '#'
  --organism[=organism]*        Organism.  Use the <name>_<taxonomy ID> notation. Example: human_9606.
				Use the 'getorg' command to look this up.
  -P, --password[=password]     MySQL password
  --password-file[=file]        File containing MySQL password
  --print-options		Print the complete list of options at the start of the script
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

EOF
    exit(0);
}

sub print_options {
    my $max_rows_p     = defined $max_rows     ? $max_rows     : 'undefined';
    my $build_p        = defined $build        ? $build        : 'undefined';
    my $options_file_p = defined $options_file ? $options_file : 'undefined';

    print <<EOF;
Command: $command

Parameters and options:

build=$build_p
check-data-dictionary=$check_data_dictionary
database=$db
determine-build=$determine_build
download-dir=$download_dir
download_schemas=$download_schemas
dump-db=$dump_db
dump-dir=$dump_dir
dump-mysql-options=$dump_mysql_options
dump-tables=$dump_tables
email-address=$email_address
engine=$engine
genome=$genome
genome-long=$genome_long
host=$host
init-table-log=$init_table_log
make-excel-file=$make_excel_file
max-rows=$max_rows_p
organism=$organism
only-create-tables=$only_create_tables
options-file=$options_file_p
password=********
password-file=$password_file
print-options=$print_options
script=$script
tables-to-download=$tables_to_download
tables-to-download-file=$tables_to_download_file
tables-to-load=$tables_to_load
tables-to-load-file=$tables_to_load_file
use-all-tables=$use_all_tables

EOF

}

#
# SUBS
#

=head1 readOptionsFile

    Read options from a file and add them to the list of command line options.
    The file may contain blank lines and comments following the '#' character.
    Options are set in <name>=<value> format, or just <name> for binary options.

    USAGE
    
	readOptionsFile('myOptions.opt');
	
    EXAMPLE

	file = myopt.txt
	
	contents:
	
	    user=myuser
	    database=mydatabase
	    only_create_tables

    NOTES
    
    * The technique is to actually add these options to the command line
      wo we can take advantage of the Getopt::Long methods
    
    * Options in options file, if specified, take precedence over those
      on the command line.
      
=cut

sub readOptionsFile {
    my ($options_file) = (@_);
    open( FILE, "<$options_file" ) or die "\nERROR: cannot open options file $options_file: $!";

    my $arg_count = @ARGV;

    while (<FILE>) {
	chomp;
	next if (/^\s*#/);    # skip line which begin with #
	next if (/^\s*$/);    # skip empty line;
	s/#.*$//;             # Remove comments at end of line

	if (/^(.*)=(.*)/) {
	    my ( $option, $value ) = ( $1, $2 );    # get option and value which are separate by '='
	    $option =~ s/^\s+//;                    # left trim
	    $option =~ s/\s+$//;                    # right trim
	    $value  =~ s/^\s+//;                    # left trim
	    $value  =~ s/\s+$//;                    # right trim

	    $arg_count++;
	    $ARGV[ $arg_count - 1 ] = "--$option=$value";
	}
	else {
	    s/^\s+//;                               # left trim
	    s/\s+$//;                               # right trim
	    $arg_count++;
	    $ARGV[ $arg_count - 1 ] = "--$_";
	}
    }

    process_options;                                # Now process command line options (again)
}

sub process_options {

    # Process command line arguments
    print_usage()
      unless &GetOptions(
	"build=i"                   => \$build,
	"check-data-dictionary"     => \$check_data_dictionary,
	"database=s"                => \$db,
	"determine-build"           => \$determine_build,
	"download-all-tables"       => \$download_all_tables,
	"download-dir=s"            => \$download_dir,
	"download-schemas"          => \$download_schemas,
	"dump-db"                   => \$dump_db,
	"dump-tables"               => \$dump_tables,
	"dump-dir=s"		    => \$dump_dir,
	"dump-mysql-options=s"	    => \$dump_mysql_options,
	"email-address=s"           => \$email_address,
	"engine=s"                  => \$engine,
	"genome=s"                  => \$genome,
	"genome-long=s"             => \$genome_long,
	"help"                      => \&print_usage,
	"H|host=s"                  => \$host,
	"init-table-log"            => \$init_table_log,
	"make-excel-file"           => \$make_excel_file,
	"max-rows=i"                => \$max_rows,
	"organism=s"                => \$organism,
	"only-create-tables"        => \$only_create_tables,
	"options-file=s"            => \$options_file,
	"P|password=s"              => \$password,
	"password-file=s"           => \$password_file,
	"print-options"             => \$print_options,
	"script=s"                  => \$script,
	"tables-to-download=s"      => \$tables_to_download,
	"tables-to-download-file=s" => \$tables_to_download_file,
	"tables-to-load=s"          => \$tables_to_load,
	"tables-to-load-file=s"     => \$tables_to_load_file,
	"use-all-tables"            => \$use_all_tables,
	"U|user=s"                  => \$user
      );
}
