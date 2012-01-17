package TableLog;

=head1 NAME

    TableLog - create/update MySQL table _loc_table_log - stores
	       summary information about dbSNP tables
   
=cut

use strict;
use warnings;
use DBI;
use LWP::UserAgent;            # For accessing the dbSNP online data dictionary
use File::stat;                # For looking up a file's timestamp
use Cwd 'abs_path';            # For looking up a data file's absolute path
use Net::Domain 'hostfqdn';    # For looking up the local machine's domain name

my $dbsnp_ftp_site = 'ftp.ncbi.nlm.nih.gov';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();

sub open_connection;
sub table_log;
sub init;
sub update;
sub make_excel_file;

my $table_log =
  '_loc_table_log';    # Stores information about tables like data file path
my $dbsnp_online_data_dictionary =
  "http://www.ncbi.nlm.nih.gov/projects/SNP/snp_db_table_description.cgi?t=";
my $dbh;               # For DBI

=head2 table_log

    * Create/update $table_log
    
    * Determine # lines in downloaded files, # rows in tables, file sizes, etc
    
    * Look up tables in dbSNP data dictionary, or record that it wasn't found
    
    USAGE
    
    table_log(%opt)
    
    OPTIONS PASSED VIA HASH
    
    db
    user
    password
    host
    init_table_log
    make_excel_file

=cut

sub table_log {
    my %opt = @_;

    die "\nERROR(log): the required parameter 'user' is not defined"
      unless $opt{user};
    die "\nERROR(log): the required parameter 'password' is not defined"
      unless $opt{password};
    die "\nERROR(log): the required parameter 'host' is not defined"
      unless $opt{host};
    die "\nERROR(log): the required parameter 'db' is not defined"
      unless $opt{db};

    open_connection(%opt);
    init(%opt) if $opt{init_table_log};
    update(%opt);
    make_excel_file(%opt) if $opt{make_excel_file};
}

=head2 open_connection

    USAGE
    
    open_connection(%opt)
    
    OPTIONS PASSED VIA HASH
    
    db
    user
    password
    host

=cut

sub open_connection {
    my %opt = @_;
    $dbh = DBI->connect( "DBI:mysql:database=$opt{db}:host=$opt{host}",
	$opt{user}, $opt{password} )
      or die "\nERROR: can't connect to database: $DBI::errstr";
    print STDOUT
"Opened connection to MySQL database $opt{host}.$opt{db} via user $opt{user}\n";
    $dbh->{PrintError} =
      0;    # When this is set to 0 the script controls the printing of errors
}

=head2 init

    Initialize the table $table_log
    
    USAGE
    
    init(%opt)
    
    OPTIONS PASSED VIA HASH
    
    db
    host
    engine
    download_dir
    ftp_dir

=cut

sub init {
    my %opt = @_;

    my $table_list = "dbsnp_table_list.txt";    # Created by Convert.pm
    die
"\nERROR: the file $table_list doesn't exist.  Download schemas and use convert command."
      unless -e $table_list;

    print STDOUT
      "Creating MySQL table $opt{db}.$table_log on server $opt{host}\n";

    $dbh->do("DROP TABLE IF EXISTS $table_log")
      or die "\nERROR: couldn't drop table $table_log: $DBI::errstr";

    my $table_log_code = <<EOF;
CREATE TABLE $table_log (
    name varchar(128) NOT NULL COMMENT 'Name of table',
    type varchar(32) NOT NULL COMMENT 'Table type - determined by schema location (SHARED,HUMAN,etc)',
    local_data_path varchar(256) NOT NULL COMMENT 'Path to data file on local machine',
    ftp_data_path varchar(256) NOT NULL COMMENT 'Path to data file on the dbSNP FTP server',
    schema_file varchar(64) NOT NULL COMMENT 'Name of the dbSNP schema file used for this table',
    local_schema_path varchar(256) NOT NULL COMMENT 'Path to the schema file on the local machine',
    ftp_schema_path varchar(256) NOT NULL COMMENT 'Path to the schema file on the dbSNP FTP server',
    downloaded boolean NOT NULL DEFAULT 0 COMMENT 'Whether data was downloaded',
    size_bytes bigint UNSIGNED COMMENT 'Size of .bcp data file',
    number_of_lines bigint UNSIGNED NULL COMMENT 'Number of lines in data file',
    loaded_into_database boolean NOT NULL DEFAULT 0 COMMENT 'Whether data was successfully loaded into the local database',
    number_of_rows bigint UNSIGNED NULL COMMENT 'Number of rows loaded',
    date_downloaded timestamp NULL COMMENT 'Date the table was downloaded from dbSNP FTP site',
    date_log_last_updated timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Date this information was last updated',
    in_data_dictionary boolean NULL COMMENT 'Whether the table is documented on the dbSNP online data dictionary',
    data_dictionary_link varchar(256) NULL COMMENT 'Hyperlink to dbSNP online data dictionary',
    PRIMARY KEY (name)
) ENGINE=$opt{engine};
EOF

    $dbh->do($table_log_code)
      or die
      "\nERROR: couldn't create $table_log: $DBI::errstr: CODE=$table_log_code";

    # Now populate it with all the tables in $table_list, which is created by
    # Convert.pm
    my @all_tables;
    my %type;
    my %schema;
    open TABLE_LIST, "<$table_list"
      or die "ERROR: cannot open the file $table_list: $!";
    print STDOUT "Reading tables and their types from $table_list\n";
    while (<TABLE_LIST>) {
	chomp;
	my ( $table, $type, $schema ) = ( split /\t/ )[ 0, 1, 2 ];
	push @all_tables, $table;
	$type{$table}   = $type;
	$schema{$table} = $schema;
    }
    close TABLE_LIST;

    for my $table_name (@all_tables) {
	my $type   = $type{$table_name};
	my $schema = $schema{$table_name};
	
	my $dd             = $type eq 'SHARED' ? "$opt{download_dir}/shared" : "$opt{download_dir}/$opt{organism}";
	my $ftp_data_dir   = $opt{ftp_dir}->{DATA}->{$type};
	my $ftp_schema_dir = $opt{ftp_dir}->{SCHEMA}->{$type};
	
       # Assuming that the data files have are still compressed on local machine
	my $local_data_path =
	  hostfqdn() . ':' . abs_path("$dd/$table_name.bcp.gz");
	my $sep = ( $type eq 'SHARED' ) ? '' : '/';
	my $ftp_data_path =
	  'ftp://' . $dbsnp_ftp_site . "$ftp_data_dir$sep$table_name.bcp.gz";

	# Assuming that the schema files have been decompressed on local machine
	my $local_schema_path = hostfqdn() . ':' . abs_path("$dd/$schema.sql");
	my $ftp_schema_path =
	  'ftp://' . $dbsnp_ftp_site . "$ftp_schema_dir$sep$schema.sql.gz";

# Don't insert date_log_last_updated, let DEFAULT current_timestamp() do its thing
	my $insert_code = <<EOF;
INSERT INTO $table_log (name,type,local_data_path,ftp_data_path,schema_file,local_schema_path,ftp_schema_path)
    VALUES ("$table_name","$type","$local_data_path","$ftp_data_path","$schema","$local_schema_path","$ftp_schema_path");
EOF
	$dbh->do($insert_code)
	  or die
"\nERROR: on inserting data into $table_log: $DBI::errstr: CODE=$insert_code";
    }
}

=head2 update

    Update the table $table_log
    
    USAGE
    
    update(%opt)
    
    OPTIONS PASSED VIA HASH
    
    db
    check_data_dictionary
    download_dir
    ftp_dir

=cut

sub update {
    my %opt        = @_;
    my $table_list = "dbsnp_table_list.txt";    # Created by Convert.pm
    die
"\nERROR: the file $table_list does not exist - download schemas and use convert command"
      unless -e $table_list;

    print "Updating $opt{db}.$table_log\n";

    # Now populate it with all the tables in $table_list, which is created by
    # Convert.pm
    my @all_tables;
    my %type;
    my %schema;
    open TABLE_LIST, "<$table_list"
      or die "ERROR: cannot open the file $table_list: $!";
    print STDOUT "Reading tables and their types from $table_list\n";
    while (<TABLE_LIST>) {
	chomp;
	my ( $table, $type, $schema ) = ( split /\t/ )[ 0, 1, 2 ];
	push @all_tables, $table;
	$type{$table}   = $type;
	$schema{$table} = $schema;
    }
    close TABLE_LIST;

    # Determine which tables have been loaded into the database
    my $code = <<EOF;
SELECT table_name FROM information_schema.TABLES
WHERE table_schema="$opt{db}";
EOF
    my $sth = $dbh->prepare($code)
      or die
"\nERROR: could not get list of tabled loaded: $DBI::errstr\nCODE:\n$code";
    $sth->execute()
      or die
"\nERROR: could not get list of tabled loaded: $DBI::errstr\nCODE:\n$code";
    my @tables_loaded = ();
    while ( my $table = $sth->fetchrow_array() ) {
	push @tables_loaded, $table unless $table eq $table_log;
    }

    # Convert to hash
    my %table_loaded;
    for (@tables_loaded) {
	$table_loaded{$_} = 1 unless $_ eq $table_log;
    }

    # Determine which tables are documented in the dbSNP online data dictionary
    my $browser = LWP::UserAgent->new if $opt{check_data_dictionary};

    for my $table_name (@all_tables) {
	my $type   = $type{$table_name};
	my $schema = $schema{$table_name};

	# Create hyperlinks: =HTTPD("<link>","label")
	# Format for dbSNP data dictionary:
	#  http://www.ncbi.nlm.nih.gov/projects/SNP/snp_db_table_description.cgi?t=SubSNP

	my $dbsnp_dd_link = "$dbsnp_online_data_dictionary$table_name";
	my $excel_entry   = "=HYPERLINK(\"$dbsnp_dd_link\",\"$table_name\")";

	# Check if $dbsnp_dd_link works
	my $dd_exists_numeric;
	if ( $opt{check_data_dictionary} ) {
	    print STDOUT
	      "Checking dbSNP online data dictionary for $table_name\n";
	    my $req    = HTTP::Request->new( GET => $dbsnp_dd_link );
	    my $res    = $browser->request($req);
	    my $html   = $res->content;
	    my $exists = $html =~ (/Found 0 Records/i) ? 'NO' : 'YES';
	    $dd_exists_numeric = ( $exists eq 'YES' ) ? 1 : 0;
	}
	else {
	    $dd_exists_numeric = 'NULL';
	}

	# Determine if data file exists on FTP site and get the size
	my $dd             = $type = 'SHARED' ? "$opt{download_dir}/shared" : "$opt{download_dir}/$opt{organism}";
	my $ftp_data_dir   = $opt{ftp_dir}->{DATA}->{$type};
	my $ftp_schema_dir = $opt{ftp_dir}->{SCHEMA}->{$type};

       # Assuming that the data files have are still compressed on local machine
	my $data_file = "$dd/$table_name.bcp.gz";

	my $size_bytes;
	my $downloaded;
	my $number_of_lines = 0;
	my $date_downloaded_epoch;

	if ( -e $data_file ) {
	    $downloaded = 1;
	    $size_bytes = -s $data_file;
	    print "Counting lines in $data_file\n";

      # *** TODO: handle errors from gunzip & wc
      # Should use 2>file when running this script to capture errors from gunzip
	    $number_of_lines = `gunzip --to-stdout $data_file | wc -l`;
	    chomp($number_of_lines);

	    # Get date last modified
	    $date_downloaded_epoch = stat($data_file)->mtime;
	}
	else {
	    $downloaded            = 0;
	    $size_bytes            = 'NULL';
	    $number_of_lines       = 'NULL';
	    $date_downloaded_epoch = 'NULL';
	}

	# Determine if tables has been loaded into the database
	my $loaded;
	my $number_of_rows;
	if ( $table_loaded{$table_name} ) {
	    $loaded         = 1;
	    $number_of_rows = "(SELECT COUNT(*) FROM $table_name)";
	}
	else {
	    $loaded         = 'NULL';
	    $number_of_rows = 'NULL';
	}

	my $insert_code = <<EOF;
UPDATE $table_log
    SET downloaded = $downloaded,
	date_downloaded = from_unixtime($date_downloaded_epoch),
	size_bytes = $size_bytes,
	number_of_lines = $number_of_lines,	
	loaded_into_database = $loaded,
	number_of_rows = $number_of_rows,
	in_data_dictionary = $dd_exists_numeric,
	data_dictionary_link = "$dbsnp_dd_link"
    WHERE name = "$table_name";
EOF
	$dbh->do($insert_code)
	  or die
"\nERROR: on inserting data into $table_log: $DBI::errstr: CODE=$insert_code";
    }
}

=head2 create_table_log_excel

    Create tab-delimited version of $table_log
    
      IN:  $db.$table_log
      OUT: $excel_file
    
    * TODO: make this more robust - make a list of columns, don't assume we have the correct order
    
    * DO WE REALLY NEED THIS?

=cut

sub make_excel_file {
    my $excel_file =
      "table_log_excel_file.txt";    # List of tables formatted for Excel
    my $excel_file_header =
"Name\tType\tData path\tFTP path\tDownloaded\tSize (bytes)\tNumber of lines\tLoaded into local database\tNumber of rows\tDate downloaded\tDate last updated\tIn dbSNP data dictionary\tdbSNP data dictionary link\n";
    my $dbsnp_dd_link_index = 12;

    open EXCEL_FILE, ">$excel_file" or die "\nERROR: can't open $excel_file";
    print STDOUT
"Creating tab-delimited file $excel_file with links formatted for Excel\n";

    print EXCEL_FILE $excel_file_header;

    # Get rows from $table_log
    my $sth = $dbh->prepare("SELECT * from $table_log")
      or die "\n  ERROR: can't prepare MySQL statement: $DBI::errstr";
    $sth->execute
      or die "\n  ERROR: can't execute MySQL statement: $DBI::errstr";

    my @row;
    while ( @row = $sth->fetchrow_array() ) {
	@row = map { defined $_ ? $_ : '' } @row;    # Convert NULL to ""

	my $dbsnp_dd_link = $row[$dbsnp_dd_link_index];
	my $name          = $row[0];
	my $excel_entry   = "=HYPERLINK(\"$dbsnp_dd_link\",\"$name\")";
	$row[$dbsnp_dd_link_index] = $excel_entry;
	print EXCEL_FILE join "\t", @row, "\n";
    }
    die
"\n ERROR: data fetching from $table_log terminated early by error: $DBI::errstr"
      if $DBI::err;

    close EXCEL_FILE;
}

1;
