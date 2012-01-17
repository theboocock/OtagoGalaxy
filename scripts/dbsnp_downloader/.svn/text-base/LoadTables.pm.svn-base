package LoadTables;

=head1 NAME

  UploadTables - load dbSNP data files into MySQL database using scripts
		 converted from MSSQL by Convert.pm.

=cut

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();

use strict;
use warnings qw(FATAL all);
use DBI;
use Text::Wrap qw(wrap $columns);    # For wrapping DBI error messages

sub load_data;
sub load_table;
sub open_connection;
sub read_tables_to_load;
sub load_script;
sub get_tables_in_database;
sub dump;

my %table_in_database = ();          # Whether a table is already in the database
my $dbh;                             # The primary connection to the MySQL database

=head2 load_data

  USAGE

  load_data(%opt)

  OPTIONS PASSED VIA HASH

  user
  password
  host
  db
  tables_to_load
  tables_to_load_file
  use_all_tables

=cut

sub load_data {

    my %opt = @_;

    die "\nERROR: the required parameter 'user' is not defined"
      unless $opt{user};
    die "\nERROR: the required parameter 'password' is not defined"
      unless $opt{password};
    die "\nERROR: the required parameter 'host' is not defined"
      unless $opt{host};
    die "\nERROR: the required parameter 'database' is not defined"
      unless $opt{db};

    print "Preparing to load dbSNP tables into MySQL database $opt{db}\n";

    # Files created by Convert.pm
    my $consolidated_file_mysql = "dbsnp_consolidated_tables_mysql.sql";
    my $table_list              = "dbsnp_table_list.txt";

    #
    # Load selected schemas and data into a local MySQL database
    #

    my $tables_to_load = $opt{tables_to_load};
    my @tables_to_load;    # Could end up being empty
    my $tables_to_load_file = $opt{tables_to_load_file};
    my $use_all_tables      = $opt{use_all_tables};

    if ($use_all_tables) {
	open TABLE_LIST, "<$table_list"
	  or die "\nError: can't open $table_list: $!";
	while (<TABLE_LIST>) {
	    push @tables_to_load, (split)[0];
	}
	close TABLE_LIST;
    }
    elsif ($tables_to_load_file) {
	read_tables_to_load( \@tables_to_load, %opt );    # *** TODO: write this sub!
    }
    elsif ( $opt{tables_to_load} ) {

	# Process parameters
	@tables_to_load = split /,/, $opt{tables_to_load};
    }

    if (@tables_to_load) {

	open_connection(%opt);

	my %table_loaded;

    # Load tables in the order specified by the user - must read through consolidated file each time
      LOAD_TABLE_LOOP: for my $table (@tables_to_load) {
	    
		get_tables_in_database(%opt);
	    
		open INFILE, "<$consolidated_file_mysql"
	      or die "ERROR: can't open $consolidated_file_mysql. ";
	  READ_CONSOL_FILE: while (<INFILE>) {
		if (/TABLE: (\w+) \((\w+)\)/) {
		    my $name = $1;
		    my $type = $2;

		    if ( ( $name eq $table ) || $use_all_tables ) {

			# Read everything between the "--" lines
			my $mysql_code = '';
			my $dashes     = <INFILE>;
		      READ_TABLE: while (<INFILE>) {
			    last READ_TABLE if /^--/ && !/WARNING/;
			    $mysql_code .= $_;
			}
			  
			$table_loaded{$table} = 1
			  unless load_table(
			    table  => $name,
			    type   => $type,
			    schema => $mysql_code,
			    %opt
			  );
		    }
		}
	    }
	    close INFILE;
	    last LOAD_TABLE_LOOP if $use_all_tables;
	}

	# Check to make sure we didn't miss anything
	for my $table (@tables_to_load) {
	    warn
"\nWARNING: there were problems loading the table \"$table\" into the MySQL database.\n"
	      . "  Check that the dbSNP schema files have been downloaded and converted to MySQL\n"
	      . "  and that $table appears in the file $consolidated_file_mysql"
	      unless $table_loaded{$table};
	}
    }    # if (@tables_to_load)
    else {
	print "No tables were specified\n";
    }
}

=head2 load_table

  USAGE

  load_table(%opt)

  OPTIONS PASSED VIA HASH

  table - name of dbSNP table
  type - SHARED/ORGANISM
  schema - MySQL code defining the schema of the table
  only_create_tables
  max_rows
  download_dir
  user
  password
  host
  db

=cut

sub load_table {

    #
    # Load a schema and data for a specified single table into a MySQL database
    #

    my %opt = @_;

    my $table = $opt{table};
    if ( $table_in_database{$table} ) {
	print "The table $table is already in the database $opt{db}. It will not be reloaded.\n";
	return 0;
    }

    my $type   = $opt{type};      # SHARED/ORGANISM
    my $schema = $opt{schema};    # Should include "create ... if not exists" if necessary

	#die "*1 schema=$schema";
	
    my $only_create_tables = $opt{only_create_tables};
    my $max_rows = $opt{max_rows};    # Maximum number of lines to read from $data_file

    my $shared_data_dir   = "$opt{download_dir}/shared";
    my $organism_data_dir = "$opt{download_dir}/$opt{organism}";

    die "\nERROR(LoadTables::load_table): table not defined"
      unless defined $table;
    die "\nERROR(LoadTables::load_table): type not defined"
      unless defined $type;
    die "\nERROR(LoadTables::load_table): schema not defined"
      unless defined $schema;

    $max_rows = "undef" unless defined $max_rows;

    my $data_file_gz;
    my $data_file;

    # *** TODO: allow for uncompressed data files

    unless ($only_create_tables) {
	$data_file_gz =
	  ( $type eq 'SHARED' )
	  ? "$shared_data_dir/$table.bcp.gz"
	  : "$organism_data_dir/$table.bcp.gz";
	$data_file =
	  ( $type eq 'SHARED' )
	  ? "$shared_data_dir/$table.bcp"
	  : "$organism_data_dir/$table.bcp";

	die "\nERROR: file $data_file_gz does not exist"
	  unless -e $data_file_gz;
    }
    my $data_file_print = $only_create_tables ? "-NOT LOADING DATA-" : $data_file_gz;

    # CREATE $table
    $dbh->do("DROP TABLE IF EXISTS $table")
      or die "\nERROR: trying to drop table $table: $DBI::errstr";

    # Process multiple statements separated by ;
    my $code            = '';
    my @lines           = split "\n", $schema;
    my $num_columns     = 0;                     # MUST COUNT!
    my $first_line      = 1;
    my $create_finished = 0;

	#warn "*3: schema=$schema";
	
    while (@lines) {
		my $line = shift @lines;

		#warn "line=$line";
		#warn "yes" if $line =~ /\r/;
		#$line =~ s/\r/\n/g;
		#warn "line mod=$line";
		#die "***";
		
		$line =~ s/\r/\n/g; # *** Quick fix: look for just ")" - end of create
		
		#warn "line=$line";
		
		$code .= $line;                   # The first one must be the CREATE line

		if ( ($code =~ /;/) || ($line =~ /^\)$/) ) { # ERROR: WE DON'T SEEM TO BE FINDING A ";" SOMETIMES - WHAT'S UP? USING getorg COMMAND
			
			unless ($create_finished) {
				print STDOUT "Initializing table \"$table\", # columns = $num_columns\n";
				$create_finished = 1;
			}
	
			unless ( $dbh->do($code) ) {
				print <<EOF;

  ERROR: table=$table
  code:

$code

DBI::errstr=$DBI::errstr
EOF
				die;
			}
	
			$code = '';
		}
	
		$num_columns++ unless ( $first_line || $create_finished );
		$first_line = 0;
    }    # while (@lines)

	#die "*4: past create table";
	
    # Load data into table using LOAD DATA LOCAL INFILE statement

    # *** TO DO: use a PIPE to direct the output of gunzip so we
    # Don't need to recompress the file afterwards

    unless ($only_create_tables) {
	print STDOUT "Reading data from $data_file_gz\n";

	#if ( system("gunzip $data_file_gz") ) {
	#    warn "\nWARNING: from \"gunzip $data_file_gz\": $?";
	#    return 1;
	#}

	#if ( !-e $data_file ) {
	#    warn "\nWARNING: could not find $data_file - did gunzip fail?";
	#    return 1;
	#}

	my $gunzip_cmd = 'gunzip --to-stdout';

	open DATA_FILE, "$gunzip_cmd $data_file_gz|"
	  or die "\nERROR: opening pipe for $gunzip_cmd $data_file_gz: $?";

	my $tmp_data_file = '_load_data_tmp.txt';
	my $tmp_data_cnt  = 0;
	while ( -e $tmp_data_file ) {
	    $tmp_data_cnt++;
	    $tmp_data_file = "_load_data_tmp_$tmp_data_cnt.txt";
	}
	open TMP_DATA_FILE, ">$tmp_data_file"
	  or die "\nERROR: opening file $tmp_data_file";

	print STDOUT "Pre-processing $data_file prior to loading data into MySQL database\n";
	print STDOUT "  Output = $tmp_data_file\n";

	my $line_count = 0;
      READ_LINES: while ( my $line = <DATA_FILE> ) {

	    # For table db_DataDictionaryNew skip lines with lots of dashes (why are they
	    # there???) This table needs additional work - some field values have \n
	    # characters in them for multiple lines

	    $line_count++;
	    last READ_LINES
	      if ( $max_rows ne "undef" ) && ( $line_count > $max_rows );

	    chomp $line;    # Important to do this or we get extra \n characters in the database
	    my @values = split( '\t', $line );

	    # TABLE MethodLine: skip if 3rd column is empty. This is probably due to
	    # line breaks in the "line" column (description of the method)
	    next READ_LINES
	      if ( $table eq 'MethodLine' ) && ( not defined $values[2] );

	    # ALL TABLES: Convert missing data to NULL using \N
	    for my $n ( 0 .. $num_columns - 1 ) {
		if ( ( not defined $values[$n] ) || ( $values[$n] eq "" ) ) {
		    $values[$n] = '\N';
		}
	    }

	    print TMP_DATA_FILE join "\t", @values;
	    print TMP_DATA_FILE "\n";
	}    # READ_LINES

	print "Closing $data_file_gz: can ignore any 'broken pipe' messages from gunzip\n"
	  if defined $max_rows;

	close DATA_FILE;
	close TMP_DATA_FILE;

	#print STDOUT "Re-compressing $data_file\n";
	#die "\nERROR: from \"gzip $data_file: $?" if system("gzip $data_file");

	my $script_file    = '_load_data.sql';
	my $tmp_script_cnt = 0;
	while ( -e $script_file ) {
	    $tmp_script_cnt++;
	    $script_file = "_load_data_$tmp_script_cnt.sql";
	}

	open SCRFILE, ">$script_file" or die "Error: cannot open $script_file";

	# Trying to use DISABLE/ENABLE KEYS to make the loading more efficient
	print SCRFILE<<EOF;
ALTER TABLE `$table` DISABLE KEYS;
LOAD DATA LOCAL INFILE '$tmp_data_file' INTO TABLE $table FIELDS TERMINATED BY '\\t';
SHOW WARNINGS;
ALTER TABLE `$table` ENABLE KEYS;
EOF

	close SCRFILE;

	#
	# Sending MySQL output to a file
	#
	# Note: it appears that the only data shown in this file are warnings
	# found, and these warnings are tab delimited. Also, MySQL doesn't
	# create this file if there are no warnings
	#
	# Example:
	# Level   Code    Message
	# Warning 1366    Incorrect integer value: 'abc' for column 'ctg_id' at row 1
	#

	my $mysql_output_file = '_mysql_out.tab';
	my $tmp_mysql_cnt     = 0;
	while ( -e $mysql_output_file ) {
	    $tmp_mysql_cnt++;
	    $mysql_output_file = "_mysql_out_$tmp_mysql_cnt.tab";
	}

	unlink($mysql_output_file);

	print STDOUT
"Loading data for table \"$table\" into MySQL\n Script file=$script_file\n Output file=$mysql_output_file\n";

	if (
	    system(
"mysql --user='$opt{user}' --password='$opt{password}' --host='$opt{host}' $opt{db} "
		  . "<$script_file >$mysql_output_file 2>$mysql_output_file"
	    )
	  )
	{
		
	    my $save_script_file = "${script_file}_$table";
	    warn "\nWARNING: after running MySQL script: $?. Saving script as $save_script_file. ";
	    rename $script_file, $save_script_file;
	    return 1;
	}

	if ( -e $mysql_output_file ) {
	    open MYFILE, "<$mysql_output_file";
	    while (<MYFILE>) {
		if (/\S/) {    # There's something there
		    close MYFILE;
		    my $save_output_file = "${mysql_output_file}_$table";
		    rename $mysql_output_file, $save_output_file;
		    warn "\nWARNING: from mysql, see file $save_output_file. ";
		    return 1;
		}
	    }
	}

	close MYFILE;
	unlink $tmp_data_file, $script_file, $mysql_output_file;    # Delete temporary files
    }    # unless ($only_create_tables)

    return 0;
}    # sub load_table

=head2 get_tables_in_database

  Initialize/Reinitialize the global hash %tables_in_database

  USAGE

  get_tables_in_database(%opt)

  OPTIONS PASSED VIA HASH

  db

=cut

sub get_tables_in_database {
    my %opt = @_;

    %table_in_database = ();    # Initialize the hash

    my $code = <<EOF;
SELECT table_name FROM information_schema.TABLES
WHERE table_schema="$opt{db}";
EOF
    my $sth = $dbh->prepare($code)
      or die "\nERROR: could not get list of tabled loaded: $DBI::errstr\nCODE:\n$code";
    $sth->execute()
      or die "\nERROR: could not get list of tabled loaded: $DBI::errstr\nCODE:\n$code";
    while ( my $table = $sth->fetchrow_array() ) {
	$table_in_database{$table} = 1;
    }
    return 0;
}

=head2 load_script

  Create locally defined tables and views from dbSNP tables.  Tables
  should be prefixed with "_loc_", and views with "_loc_v".

  USAGE

  load_script(%opt)

  OPTIONS PASSED VIA HASH

  script - the script file
  update_script
  build
  genome
  genome_long
  db
  user
  password
  max_rows

=cut

sub load_script {
    my %opt = @_;

    my $script_file = $opt{script};
    my $script_file_mod;
    my $script_file_log;
    my $script_file_err;

    my @variables = qw(build genome_long genome max_rows);
    if ( $opt{update_script} ) {

	$script_file_mod = "$script_file.mod";

	# Replace $build and $genome with parameters in $script_file
	print STDOUT "Updating the script $script_file with the following substitutions:\n";
	for my $var (@variables) {
	    print " \$$var = $opt{$var}\n" if defined $opt{$var};
	}
	print STDOUT "  Revised script = $script_file_mod\n";

	open SCRIPT, "<$script_file"
	  or die "\nERROR: cannot open $script_file: $!";
	open MOD, ">$script_file_mod"
	  or die "\nERROR: cannot open $script_file_mod: $!";
	print MOD "USE $opt{db};\n";

	# Replace $build, $genome, etc, with corresponding options
	while (<SCRIPT>) {

	    # Note: must process genome_long before genome
	    for my $str (@variables) {
		if (/\$$str/) {
		    if ( defined $opt{$str} ) {
			s/\$$str/$opt{$str}/g;
		    }
		    else {
			warn "\nWARNING: found \"\$$str\" in $script_file "
			  . "but corresponding option is not defined";
		    }
		}
	    }
	    print MOD $_;
	}
	close SCRIPT;
	close MOD;
    }
    else {
	$script_file_mod = $script_file;
    }

    $script_file_log = "$script_file_mod.tab";
    $script_file_err = "$script_file_mod.err";

    # Execute $script_file_mod
    # Now uwing --force to keep going if there are errors.  This is useful if, for example,
    # keys already exist when we try to create them
    
    my $cmd =
"mysql --user='$opt{user}' --password='$opt{password}' '$opt{db}' --verbose --table --force --show-warnings "
      . "< $script_file_mod "
      . "> $script_file_log "
      . "2> $script_file_err";

    print STDOUT
"Executing MySQL script $script_file_mod\n  Output file = $script_file_log\n  Error file = $script_file_err\n";

    if ( system($cmd) ) {
	print STDOUT "\nWARNING: possible script error: $?\n";
    }
    else {
	print STDOUT "$script_file_mod executed sucessfully\n";
    }

    print STDOUT "Contents of $script_file_log:\n\n";
    system("cat $script_file_log");
    print STDOUT "Contents of $script_file_err:\n\n";
    system("cat $script_file_err");
}

=head2 load_script

  Initialize global variable $dbh

  USAGE

  open_connection(%opt)

  OPTIONS PASSED VIA HASH

  db
  host
  user
  password

=cut

sub open_connection {
    my %opt = @_;

    #$dbh = DBI->connect( "DBI:mysql:database=$opt{db}:host=$opt{host}", $opt{user}, $opt{password} )
    #  or die "\nERROR: can't connect to database: $DBI::errstr";

    die "\nERROR: option --database is not defined" unless defined $opt{db} && $opt{db} ne "";
    
    $dbh = DBI->connect( "DBI:mysql:host=$opt{host}", $opt{user}, $opt{password} )
	or die "\nERROR: can't connect to database: $DBI::errstr";
	
    $dbh->do("CREATE DATABASE IF NOT EXISTS $opt{db}")
	or die "\nERROR: creating database $opt{db}: $DBI::errstr";
    
    $dbh->do("USE $opt{db}")
	or die "\nERROR: selecting database $opt{db}: $DBI::errstr";

    print STDOUT "Opened connection to MySQL database $opt{host}.$opt{db} via user $opt{user}\n";
    $dbh->{PrintError} = 0;    # When this is set to 0 the script controls the printing of errors
}

=head2 read_tables_to_load

  USAGE

  read_tables_to_load($tables_to_load (array ref), %opt)
  
  OPTIONS PASSED VIA HASH
  
  tables_to_load_file

=cut

sub read_tables_to_load {
    my ( $tables_to_load, %opt ) = @_;

    open TTLF, "<$opt{tables_to_load_file}"
      or die "\nERROR: can't open $opt{tables_to_load_file}: $!";
    print STDOUT "Reading tables to load from file $opt{tables_to_load_file}\n";

    @$tables_to_load = ();
  LOAD_LOOP: while (<TTLF>) {
	chomp;
	s/^\s+//;    # Trim leading whitespace
	next unless /\S/;    # Skip blank lines
	next if /^#/;        # Allow comments
	if (/\$build/) {
	    if ( defined $opt{build} ) {
		s/\$build/$opt{build}/g;
	    }
	    else {
		warn "\nWARNING: found variable \$build in file $opt{tables_to_load_file} ($_)\n"
		  . "  but the option --build is not defined";
		next LOAD_LOOP;
	    }
	}
	if (/\$genome/) {
	    if ( defined $opt{genome} ) {
		s/\$genome/$opt{genome}/g;
	    }
	    else {
		warn "\nWARNING: found variable \$genome in file $opt{tables_to_load_file} ($_)\n"
		  . "  but the option --genome is not defined";
		next LOAD_LOOP;
	    }
	}
	push @$tables_to_load, $_;
    }
    close TTLF;
}

sub compare_builds {

    my %opt = @_;

    # Compare tables in between db and db2.
    # Assuming username and password are common

    # See query_browser/compare.qbquery
}

sub dump {
    my %opt = @_;
    
    print STDOUT "\nERROR: dump directory $opt{dump_dir} does not exist"
	unless -e $opt{dump_dir};
    
    print STDOUT "\nWARNING: neither option --dump-db or --dump-tables was specified\n"
	unless $opt{dump_db} || $opt{dump_tables};

    if ($opt{dump_db}) {
	my $cmd = "mysqldump $opt{dump_mysql_options} $opt{db} | gzip > $opt{dump_dir}/$opt{db}.sql.gz";
	print "Executing command: $cmd\n";
	die "\nERROR: $?" if system($cmd);
    }

    if ($opt{dump_tables}) {
	open_connection(%opt);
	
	# Get list of tables
	my $sth = $dbh->prepare("SELECT table_name FROM information_schema.TABLES WHERE TABLE_SCHEMA='$opt{db}'");
	$sth->execute() or die "\nERROR: getting table list from database $opt{db}: $DBI::errstr";
	while (my $table_name = $sth->fetchrow_array) {
	    #print "table=$table_name\n";
	    my $cmd = "mysqldump $opt{dump_mysql_options} $opt{db} $table_name | gzip > $opt{dump_dir}/$table_name.sql.gz";
	    print "Executing command: $cmd\n";
	    die "\nERROR: $?" if system($cmd);
	}
    }
}

1;
