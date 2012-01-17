package Download;

=head1 NAME

    Download - download schema and data files from dbSNP FTP server
    
=cut

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();

use strict;
use warnings qw(FATAL all);
use DBI;
use Net::FTP;
use Cwd;

# Local Modules
use Convert;
use LoadTables;

sub download_tables;
sub download_all_schemas;
sub ftp;
sub determine_build;
sub determine_org;

my $dbsnp_ftp_site = 'ftp.ncbi.nlm.nih.gov';
my $org_table = 'OrganismTax';
my $org_schema = 'dbSNP_main_table';

=head2 download_tables

    USAGE

    download_tables(%opt)
 
    Input

    * Files from dbSNP FTP server

    Output

    * Files from dbSNP FTP server saved to local directory

    Options passed via hash

    determine_build
    download_all_tables
    tables_to_download
    tables_to_download_file
    download_schemas

=cut

sub download_tables {
    my %opt = @_;
    
    # Try to determine the organism
    if ( $opt{determine_org} ) {
	determine_org(%opt);
	return 0;
    }
    
    # Try to determine the build
    if ( $opt{determine_build} ) {
	determine_build(%opt);
	return 0;
    }

    my $table_list          = "dbsnp_table_list.txt";    # Created by Convert.pm
    my $tables_to_download  = $opt{tables_to_download};  # Comma-delimited
    my $download_all_tables = $opt{download_all_tables}; # Boolean

    # tables_to_download_file: single-column, takes precedence over tables_to_download
    my $tables_to_download_file = $opt{tables_to_download_file};

    # Schemas
    download_all_schemas(%opt) if $opt{download_schemas};

    # Tables
    my @tables_to_download = ();    # Just names, we need to look up types

    if ($tables_to_download_file) {
	open TTDF, "<$tables_to_download_file"
	  or die "\nERROR: cannot open $tables_to_download_file: $!";
	print STDOUT "Reading tables from $tables_to_download_file\n";
	
	DOWNLOAD_LOOP: while (<TTDF>) {
	    chomp;
	    s/^\s+//;               # Trim leading whitespace
	    next unless /\S/;       # Skip blank lines
	    next if /^#/;           # Allow comments in the table list file

	    if (/\$build/) {
		if (defined $opt{build}) {
		    s/\$build/$opt{build}/g;
		} else {
		    warn "\nWARNING: found variable \$build in file $tables_to_download_file ($_)\n" .
			 "  but the option --build is not defined";
		    next DOWNLOAD_LOOP;
		}
	    }
	    if (/\$genome/) {
		if (defined $opt{genome}) {
		    s/\$genome/$opt{genome}/g;
		} else {
		    warn "\nWARNING: found variable \$genome in file $tables_to_download_file ($_)\n" .
			 "  but the option --genome is not defined";
		    next DOWNLOAD_LOOP;
		}
	    }
	    
	    push @tables_to_download, $_;
	}
	close TTDF;
    }
    elsif ($tables_to_download) {
	@tables_to_download = split /,/, $tables_to_download;
    }

    if ( @tables_to_download || $download_all_tables ) {
	die
"\nERROR: the file $table_list does not exist.  Use --download-schemas option to create it."
	  unless -e $table_list;

	# There are tables to download.
	# If $download_all_tables we read the list from the schema files.
	my @all_tables;
	my %type;
	open TABLE_LIST, "<$table_list"
	  or die "ERROR: cannot open the file $table_list: $!";
	print STDOUT "Reading tables and their types from $table_list\n";
	while (<TABLE_LIST>) {
	    chomp;
	    my ( $table, $type ) = ( split /\t/ )[ 0, 1 ];
	    push @all_tables, $table;
	    $type{$table} = $type;
	}
	close TABLE_LIST;

	my $ftp_err_msg;
	if ($download_all_tables) {
	    for my $table (@all_tables) {
		my $type = $type{$table};
		die
"\nERROR: cannot find type for the table $table in the file $table_list - check spelling"
		  unless defined $type;
		print STDOUT
		  "WARNING: table $table (type = $type): $ftp_err_msg\n"
		  if $ftp_err_msg = ftp(
		    download_type => "DATA",
		    name          => $table,
		    domain        => $type,
		    %opt
		  );
	    }
	}
	else {
	    for my $table (@tables_to_download) {
		my $type = $type{$table};
		die
"\nERROR: cannot find type for the table $table in the file $table_list - check spelling"
		  unless defined $type;

		print STDOUT
		  "WARNING: table $table (type = $type): $ftp_err_msg\n"
		  if $ftp_err_msg = ftp(
		    download_type => "DATA",
		    name          => $table,
		    domain        => $type,
		    %opt
		  );
	    }
	}
    }
}


=head2 download_all_schemas

    Download all dbSNP schema files and convert to MySQL

    USAGE

    download_all_schemas(%opt)
 
    Input

    * Files from dbSNP FTP server

    Output

    * Files from dbSNP FTP server saved to local directory

    Options passed via hash

    email_address
    ftp_dir

=cut

sub download_all_schemas {

    # Download all files of the form "*.sql" from the SHARED and ORGANISM schema
    # directories
    my %opt           = @_;
    my $email_address = $opt{email_address};

    for my $type (qw(SHARED ORGANISM)) {
	print "Getting list of $type schemas from $dbsnp_ftp_site\n";

	my $ftp;
	$ftp = Net::FTP->new( "$dbsnp_ftp_site", Debug => 0, Passive => 1 )
	  or die "Cannot connect to $dbsnp_ftp_site : $@";
	$ftp->login( "anonymous", "$email_address" )
	  or die "Cannot log in ", $ftp->message;
	print STDOUT
	    "Successfull anonymous login into $dbsnp_ftp_site, password = $email_address\n";

	$ftp->pasv() or die "\nERROR: cannot use passive mode: ", $ftp->message;
	$ftp->binary()
	  or die "\nERROR: cannot use binary transfer: ", $ftp->message;
	my $dir = $opt{ftp_dir}->{SCHEMA}->{$type};
	$ftp->cwd($dir)
	  or die "\nERROR: cannot enter directory $dir: ", $ftp->message;

	my @schema_files = ();
	if ( my $ls = $ftp->ls ) {
	    for my $file (@$ls) {
		push @schema_files, $file if $file =~ /.sql.gz$/;
	    }
	}
	else {
	    die "\nERROR: getting directory listing: ", $ftp->message;
	}
	$ftp->quit;

	for my $schema_file (@schema_files) {
	    my $ftp_err_msg;
	    print STDOUT "Problem downloading schema $schema_file (type = $type): $ftp_err_msg\n"
	      if $ftp_err_msg = ftp(
		      download_type => "SCHEMA",
		      name          => $schema_file,
		      domain        => $type,
		      %opt
	      );
	}
    }

    # Convert MSSQL code to MySQL
    Convert::consolidate_schemas(%opt);
}


=head2 ftp

    USAGE

    ftp(%opt)
 
    Input

    * Files from dbSNP FTP server

    Output

    * Files from dbSNP FTP server saved to local directory

    Options passed via hash

    name - name of table
    download_type - DATA/SCHEMA
    domain - SHARED/ORGANISM
    email_address
    ftp_dir
    download_dir

=cut

sub ftp {
    my %opt = @_;

    my $name   = $opt{name};
    my $select = $opt{download_type};    # DATA or SCHEMA
    my $type   = $opt{domain};           # SHARED, ORGANISM, etc
    my $short_type    = $type eq 'SHARED' ? 'SHARED' : 'ORGANISM';
    my $email_address = $opt{email_address};

    die "\nERROR: type \"$type\" is not SHARED or ORGANISM"
      unless ( $type eq 'SHARED' ) || ( $type eq 'ORGANISM' );

    my $ftp_dir = $opt{ftp_dir}->{$select}->{$short_type};

    my $file = $select eq 'SCHEMA' ? $name : "$name.bcp.gz";
    my $pos = index( $file, '.gz' );
    my $file_unzipped = substr( $file, 0, $pos );
    
    my $download_subdir = $type eq 'SHARED' ? 'shared' : $opt{organism};
	
    print STDOUT
"Attempting to download \"$file\" (type = $type) from $dbsnp_ftp_site to $opt{download_dir}/$download_subdir\n";
    my $cwd = cwd;    # Save the original directory

    # Change working directory to $opt{download_dir}/$short_type
    
    print STDOUT "Changing working directory to $opt{download_dir}\n";
    
    die "\nERROR: the directory $opt{download_dir} doesn't exist"
      unless -e $opt{download_dir};
    die "\nERROR: could not change directory to $opt{download_dir}: $!"
      unless chdir($opt{download_dir});

    print STDOUT "Changing to subdirectory $download_subdir\n";
    unless (-e $download_subdir) {
	die "\nERROR: could not create directory '$download_subdir': $!"
	    unless mkdir($download_subdir);
    }
    die "\nERROR: could not change directory to '$download_subdir': $!"
      unless chdir($download_subdir);

    if ( -e $file ) {
	print STDOUT "$file already exists - will not download\n";
    }
    elsif ( -e "$file_unzipped" ) {
	print STDOUT "Unzipped $file already exists - will not download\n";
    }
    else {

	my $ftp;
	
	# Connect to dbSNP FTP site
	$ftp = Net::FTP->new( "$dbsnp_ftp_site", Debug => 0, Passive => 1 )
	  or die "Cannot connect to $dbsnp_ftp_site :", $ftp->message;
	
	# *** TO DO: if cannot connect, re-try N times with M seconds between
	# attempts - create options for M and N.
	# Can this be done with Net::FTP?
	
	# Login as anonymous
	$ftp->login( "anonymous", "$email_address" )
	  or die "Cannot log in ", $ftp->message;

	print STDOUT
"Successfull anonymous login into $dbsnp_ftp_site, password = $email_address\n";

	$ftp->pasv() or die "\nERROR: cannot use passive mode ", $ftp->message;
	$ftp->binary()
	  or die "\nERROR: cannot use binary transfer ", $ftp->message;
	$ftp->cwd("$ftp_dir")
	  or die "\nERROR: cannot enter directory ", $ftp->message;

	if ( $ftp->get("$file") ) {
	    print STDOUT "File $file successfully downloaded\n";

	    #  my $pwd=$ftp->pwd() or die "cannot show current directory";

	    if ( my $mdtm = $ftp->mdtm("$file") ) {
		my $modified_time = localtime($mdtm);
		print STDOUT "File $file last updated at $modified_time\n";
	    }
	    else {
		print STDOUT
		  "\nWARNING: cannot show last modification time of $file ",
		  $ftp->message;
	    }

	    # Compare size of file on FTP server and local machine
	    if ( my $file_size = $ftp->size("$file") ) {
		print STDOUT "File $file size is $file_size bytes\n";
		my $file_size_local = -s $file
		  or die
		  
		  "\nERROR: could not determine local file size for $file: $!";

		if ( $file_size_local != $file_size ) {
		    print STDOUT
"\nERROR:  file size of $file on FTP site ($file_size bytes) != size of $file at local ($file_size_local)\n";
		    return "File size mismatch";
		}

		print STDOUT
"FTP file size ($file_size bytes) agrees with downloaded file size\n";
	    }
	    else {
		print STDOUT "\nWARNING: cannot get size of $file ",
		  $ftp->message;
	    }

	    $ftp->quit;

	    # Only decompress schema files
	    #   Data files are temporarily decompressed when loaded into MySQL database
	    if ( $select eq 'SCHEMA' ) {
		print STDOUT "Decompressing $file\n";
		die "\nERROR: decompressing $file" if system("gunzip $file");
	    }

	}
	else {
	    print STDOUT "\nWARNING: cannot get $file: ", $ftp->message;
	}

    }

    die "\nERROR: could not change back to current directory: $!"
      unless chdir($cwd);
    return 0;
}


=head2 determine_org

    USAGE

    determine_build(%opt)	
 
    Input

    * Files from dbSNP FTP server
    * Speficially the table $org_table

    Output

    * Files from dbSNP FTP server saved to local directory
    * Some tables are loaded into specified MySQL database
    * Taxonomy ID for specified organism, if found

    Options passed via hash

    organism
    download_dir
    db

=cut

sub determine_org {
    my %opt      = @_;
    my $organism = $opt{organism};
    print
"Attempting to determine the taxonomy ID and dbSNP database name for organism \"$organism\"\n";

    # Need to get schema and convert to MySQL
    # Download $org_schema
    my $ftp_err_msg;
    if (
	$ftp_err_msg = ftp(
	    name          => "$org_schema.sql.gz", # *** Need .gz here, but not below?
	    download_type => 'SCHEMA',
	    domain        => 'SHARED',
	    %opt
	)
      )
    {
	die "\nERROR: could not download data for table $org_table: $ftp_err_msg";
    }

    # Download $org_table
    if (
	$ftp_err_msg = ftp(
	    name          => $org_table,
	    download_type => 'DATA',
	    domain        => 'SHARED',
	    %opt
	)
      )
    {
	die "\nERROR: could not download data for table $org_table: $ftp_err_msg";
    }

    Convert::consolidate_schemas(%opt);
    
    my %opt2 = %opt;
    $opt2{tables_to_load} = $org_table;
    LoadTables::load_data(%opt2);

    my $dbh = DBI->connect( "DBI:mysql:database=$opt{db}:host=$opt{host}",
	$opt{user}, $opt{password} )
      or die "\nERROR: can't connect to database: $DBI::errstr";
    print STDOUT
"Opened connection to MySQL database $opt{host}.$opt{db} via user $opt{user}\n";
    $dbh->{PrintError} =
      0;    # When this is set to 0 the script controls the printing of errors

    # *** Convert $organism to lowercase
    
    my $code = "SELECT organism,tax_id,common_name,database_name FROM $opt{db}.$org_table WHERE " .
               "(lower(organism) like '\%$organism\%') OR (lower(common_name)) like '\%$organism\%' " .
	       "OR (lower(database_name) like '\%$organism\%')";
    my $sth = $dbh->prepare($code);
    $sth->execute
	or die "\nERROR: could not execute $code: $DBI::errstr";
    
    my $first = 1;
    my $found;
    
    while (my @fields = $sth->fetchrow_array) {
	if ($first) {
	    print "The following organisms match \"$organism\":\n\n";
	    $first=0;
	    $found = 1;
	}
	print "Organism: $fields[0]\n";
	print "Taxonomy ID: $fields[1]\n";
	print "Common name: $fields[2]\n";
	print "Database name (use this for the --organism argument): $fields[3]\n\n";
    }
    
    print "No organisms matched \"$organism\"\n" unless $found;
    return 0;
}


=head2 determine_build

    USAGE

    determine_build(%opt)	
 
    Input

    * Files from dbSNP FTP server

    Output

    * Files from dbSNP FTP server saved to local directory
    * Some tables are loaded into specified MySQL database
    * The current dbSNP build and genome versions, if found

    Options passed via hash

    organism
    download_dir
    db

=cut

sub determine_build {
    my %opt      = @_;
    my $organism = $opt{organism};
    print
"Attempting to determine the current genome and build for organism $organism\n";

    # Look for genome and build in various schema and data files
    my $check_table = 'ContigInfo';    # *** Could also put a list here
    my $check_schema_file = "${organism}_table.sql";
    my $check_type = 'ORGANISM';
    
    # Need to get schemas and convert to MySQL
    download_all_schemas(%opt);

    # Look for build and genome in $check_schema_file
    print
"Will look for the expression b<build>${check_table}_<genome> in the file $check_schema_file\n";
    my $dd = $check_type eq 'SHARED' ? "$opt{download_dir}/shared" : "$opt{download_dir}/$organism";
    
    open SCHEMA_FILE, "<$dd/$check_schema_file"
      or die "\nERROR: could not open $dd/$check_schema_file: $!";

    my $found = 0;
    my $full_table;

  SCHEMA_LOOP: while (<SCHEMA_FILE>) {
	if (/b(\d+)_${check_table}_(\w+)/) {
	    $full_table = $&;
	    print
	      "\nFound table $full_table\n\n GENOME = $2\n\n BUILD  = $1\n\n";
	    $found = 1;
	    last SCHEMA_LOOP;
	}
    }
    close SCHEMA_FILE;
    print "Could not determine the genome and build\n" unless $found;

    # Look for 'long' version of genome in $full_table. Example: GRCh37
    print "Looking up the different genome builds (example: GRCh37)\n";
    my $ftp_err_msg;
    if (
	$ftp_err_msg = ftp(
	    name          => $full_table,
	    download_type => 'DATA',
	    domain        => 'ORGANISM',
	    %opt
	)
      )
    {
	die "\nERROR: could not download data for table $full_table: $ftp_err_msg";
    }

    my %opt2 = %opt;
    $opt2{tables_to_load} = $full_table;
    LoadTables::load_data(%opt2);

    print "Looking up list of genome builds in $full_table:\n";
    print
"  Consider 'GRC' builds for human data. This result can be used for the\n";
    print "  --genome-long option in the 'load --load-script' command.\n\n";

    # *** Should probably use DBI for this
    die "\nERRORL: from MySQL: $?"
      if system(
	"mysql  --user='$opt{user}' --password='$opt{password}' --host='$opt{host}' --table -e \"SELECT DISTINCT group_label AS Build FROM $opt{db}.$full_table\""
      );

    return 0;
}

1;
