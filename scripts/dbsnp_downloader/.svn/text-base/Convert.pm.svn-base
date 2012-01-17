package Convert;

=head1 NAME

    Convert - convert dbSNP MSSQL code to MySQL
    
=cut

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();


use strict;
use warnings qw(FATAL all);
use File::Basename 'basename';

sub consolidate_schemas;
sub convert_constraint;
sub convert_index;
sub convert_schema;
sub print_underline;

my $dbsnp_ftp_site = 'ftp.ncbi.nlm.nih.gov';

my $table = {}; # Big table hash containing code - see subroutine extract_code
my @tables = (); # All tables found in the schema files
  
=head1 consolidate_schemas

    This subroutine will read in the MSSQL schemas from dbSNP,
    consolidate them into a file, and convert to MySQL in separate file.
    
    USAGE

	consolidate_schemas(%opt)
 
    IN:  $opt{download_dir}/<subdir>/*.sql
       
    OUT: ./$consolidated_file
	 ./$consolidated_file_mysql

    OPTIONS PASSED VIA HASH

    download_dir
    engine
    ftp_dir

=cut

sub consolidate_schemas {
    my %opt = @_;

    my $shared_schema_dir   = "$opt{download_dir}/shared";
    my $organism_schema_dir = "$opt{download_dir}/$opt{organism}";
    my $engine              = $opt{engine};
    my $ftp_dir             = $opt{ftp_dir};

    # Output files
    my $table_list = "dbsnp_table_list.txt"; # Simple tab-delimited list of tables *** All the tables?
    my $consolidated_file       = "dbsnp_consolidated_tables.txt";
    my $consolidated_file_mysql = "dbsnp_consolidated_tables_mysql.sql";

    my $type; # SHARED, HUMAN_9606, etc. Determined by what dbSNP MS SQL file we're reading
    my $infile; # Various schema files downloaded from dbSNP

    print STDOUT "Converting dbSNP MSSQL files to MySQL\n";
    
    #
    # Populate the global hash reference $table
    #

    my @schema_files = ( glob("$shared_schema_dir/*.sql"), glob("$organism_schema_dir/*.sql") );
    
    # First do the tables
  TABLES_ONLY: for my $infile (@schema_files) {
	next TABLES_ONLY unless $infile =~ /_table.sql$/;
	extract_code( infile => $infile, %opt );
    }

    # Now the rest
  THE_REST: for my $infile (@schema_files) {
	next THE_REST if $infile =~ /_table.sql$/;
	extract_code( infile => $infile, %opt );
    }

    #
    # Create $consolidated_file - the original MSSQL code from dbSNP
    #

    open OUTFILE, ">$consolidated_file"
      or die "ERROR: cannot open $consolidated_file: $!";
    select OUTFILE;

    print STDOUT "Saving consolidated dbSNP MSSQL code to $consolidated_file\n";

    my $date = `date`;
    chomp($date);
    print <<EOF;
###################################################################
dbsnp.pl
$date
###################################################################

TABLE TYPES
===========

TYPE            DIRECTORY IN ftp://$dbsnp_ftp_site
----            -----------------------------------------------------
SCHEMA
   SHARED       $ftp_dir->{SCHEMA}->{SHARED}
   ORGANISM     $ftp_dir->{SCHEMA}->{ORGANISM}
DATA
   SHARED       $ftp_dir->{DATA}->{SHARED}
   ORGANISM     $ftp_dir->{DATA}->{ORGANISM}
   
EOF

    # First print the list of tables grouped by SHARED/ORGANISM
    print_underline "Table List", '=';

    print "\n";
    printf "     %-33s%-32s\n", "Name", "Type";
    printf "     %-33s%-32s\n", "----", "----";

    my $n = 0;
    for my $table_name (@tables) {
	$n++;
	my $type = $table->{$table_name}->{type};
	die "\nERROR: no type defined for table $table_name"
	  unless defined $type;

	printf "%3d%-35s%-32s\n", $n, ". $table_name", $type;
    }

    # Now print the MSSQL code: schemas, constraints and indexes
    print "\n";
    print_underline "Table Schemas, Constraints and Indexes", '=';

    for my $table_name (@tables) {
	my $type = $table->{$table_name}->{type};
	print_underline "TABLE: $table_name ($type)", '=';
	print_underline "Schema";
	print "\n", $table->{$table_name}->{schema};

	print_underline "Constraints";
	my $constraint = $table->{$table_name}->{constraint};
	$constraint = "NO CONSTRAINTS FOUND\n"
	  unless ( defined $constraint ) && ( $constraint ne '' );
	print "\n$constraint";

	print_underline "Indexes";
	my $index = $table->{$table_name}->{index};
	$index = "NO INDEXES FOUND\n"
	  unless ( defined $index ) && ( $index ne '' );
	print "\n$index";
    }

    close OUTFILE;

#
# Convert schemas from MSSQL to MySQL - create $consolidated_file_mysql
#
# Also create $table_list: 3 columns
#  Table name
#  Type - SHARED/ORGANISM
#  Schema file name -  without .sql suffix.
#     Examples: dbSNP_main_table, human_9606_table
#
# $table_list is used as input for future code in order to look up the table type
# and the schema file
#

    open OUTFILE, ">$consolidated_file_mysql"
      or die "ERROR: cannot open $consolidated_file_mysql: $!";
    print STDOUT
      "Converting MSSQL to MySQL and saving to $consolidated_file_mysql\n";
    open TABLE_LIST, ">$table_list" or die "ERROR: cannot open $table_list: $!";
    print STDOUT
      "Saving a list of tables and their types in the file $table_list\n";

    select OUTFILE;

    print <<EOF;
-- Convert.pm
-- $date

-- The following schemas have been converted from MSSQL to MySQL
EOF
    for my $table_name (@tables) {
	my $type        = $table->{$table_name}->{type};
	my $schema_file = $table->{$table_name}->{schema_file};

	# Print schema path as well
	print TABLE_LIST "$table_name\t$type\t$schema_file\n";
	print <<EOF;

-- TABLE: $table_name ($type)
--
EOF

	# Print schema (CREATE TABLE statement)
	print convert_schema( $table_name, $table->{$table_name}->{schema},
	    $engine );

	# Print constraints
	my $constraint = $table->{$table_name}->{constraint};
	my $found_constraint = ( defined $constraint ) && ( $constraint ne '' );
	print convert_constraint( $table_name, $constraint )
	  if $found_constraint;

	# Print indexes
	my $index = $table->{$table_name}->{index};
	print convert_index($index) if ( defined $index ) && ( $index ne '' );
	print "--\n";
    }

    close OUTFILE;
    close TABLE_LIST;

    select STDOUT;
}

=head1 extract_code

    * Populate the global hash reference $table:
    
        $table->{<table name>}->{<type, schema, constraint, index>} = value

        type: SHARED/ORGANISM
	schema: MSSQL "CREATE TABLE" code
	contraint: MSSQL constraint code
	index: MSSQL index code
	
	This code is converted to MySQL by the subroutines convert_schema,
	convert_constraint and convert_index.
	
    * Skip dbSNP views
    
    USAGE

    extract_code(%opt)

    OPTIONS PASSED VIA HASH

    infile

=cut

sub extract_code {
    my %opt = @_;

    my $infile = $opt{infile};
    my $type = ( $infile =~ /dbSNP_(main|sup)/ ) ? 'SHARED' : 'ORGANISM';
    
    # Determine class of the SQL file: table, index, or view
    unless ($infile =~ /_(table|index|constraint|view).sql$/) {
	warn "\nWARNING: cannot determine the class of $infile (table/index/view)";
	print STDOUT "  This may not be a dbSNP file\n";
	print STDOUT "  Suggestion: store only dbSNP SQL files in the --download-dir directory\n";
	print STDOUT "  Suggestion: do not use '.' for the --download-dir directory\n";
	return 1;
    }

    my $class = $1;
    return 0 if $class eq 'view';

    open INFILE, "<$infile" or die "ERROR: cannot open $infile: $!";
    print STDOUT "Processing $infile, type = $type, class = $class\n";

    # Define keywords to search for
    my %kw = (
	table      => 'CREATE TABLE',
	index      => 'CREATE .* ON',
	constraint => 'ALTER TABLE'
    );

    while (<INFILE>) {
	if (/$kw{$class} \[(\w+)\]/) {
	    my $table_name = $1;

	    if ( $class eq 'table' ) {
		die "\nERROR: schema for table $table_name already exists"
		  if defined $table->{$table_name};
	    }
	    else {
                # Check b130_MapLinkBase_36_3 in human_9606_index.sql
		if (! defined $table->{$table_name}) {

		    # Table has no schema - skip all indexes, contraints and views
		    warn "\nWARNING: the table $table_name was not found in any schema file\n"
                        . "  such as dbSNP_main_table. Skipping this $class.\n\n";
                    
                    return 0;
		}
	    }

	    # Populate the hash $table
	    unless ( defined $table->{$table_name} ) {
		$table->{$table_name}               = {};
		$table->{$table_name}->{schema}     = '';
		$table->{$table_name}->{constraint} = '';
		$table->{$table_name}->{index}      = '';
		$table->{$table_name}->{type}       = $type;
		$table->{$table_name}->{schema_file} =
		  basename( $infile, '.sql' );
	    }

	    push @tables, $table_name
	      if $class eq 'table';    # Only done when processing table code

	    my $code = $_;
	  READ_CODE: while (<INFILE>) {
		last READ_CODE if /^GO/;
		$code .= $_;
	    }

	    if ( $class eq 'table' ) {
		$table->{$table_name}->{schema} = $code;
	    }
	    else {
		$table->{$table_name}->{$class} .= $code;
	    }
	}
    }
    close INFILE;
}

=head1 convert_schema

    USAGE

    convert_schema($name,$schema,$engine)

=cut

sub convert_schema {
  my ($name,$schema,$engine) = @_;
  my $schema2 = '';

  my @lines = split "\n",$schema;
  for (@lines) {

    # CHANGES FOR ALL TABLES

    s#[\[\]]##g;		# Remove brackets
    s/\)\n/\);\n/;	        # Add semicolon to end of table statement
    s/char \(/char(/;		# Remove space between varchar and (
    s/ ,/,/g;			# Remove space before comma

    s/ varchar\(\d+\)/ text/ if (m/varchar\((\d+)\)/) and ($1 > 255); # Use "text" instead of "varchar(n)" if n > 255
    s/\)$/\);/;

    s/ smalldatetime/ varchar(32)/g; # Trouble w/dbSNP dates, like "2000-08-25 17:02:00.0" - the .0 at the end.
    s/ datetime/ varchar(32)/g;
    s/ real/ float/g;
    s/ bit/ boolean/g;

    # Don't use IDENTITY (1,1) - I think this is for auto increment. Hopefully the IDs are already in their data files.
    s/IDENTITY \(1, 1\) //;

    # TABLE IndivSourceCode: increase width of src_type
    s/src_type varchar\(10\)/src_type varchar\(30\)/ if $name eq 'IndivSourceCode';

    # TABLE Method: change method_class tinyint to method_class UNSIGNED tinyint
    s/method_class tinyint/method_class tinyint UNSIGNED/ if $name eq 'Method';

    # TABLE MethodLine: change line_num tinyint to line_num UNSIGNED tinyint
    s/line_num tinyint/line_num tinyint UNSIGNED/ if $name eq 'MethodLine';

    # TABLE PopLine: change NOT NULL to NULL for line_num
    s/line varchar\(255\) NOT NULL/line varchar\(255\) NULL/ if $name eq 'PopLine';

    # TABLE SNP: change map_property tinyint to map_property smallint
    s/map_property tinyint/map_property smallint/ if $name eq 'SNP';

    # TABLE SnpValidationCode: change abbrev varchar(40) to abbrev varchar(80)
    s/abbrev varchar\(40\)/abbrev varchar\(80\)/ if $name eq 'SnpValidationCode';

    # TABLE SubSNP: increase the size of the table
    s/\);/\) MAX_ROWS=1000000000 AVG_ROW_LENGTH=100;/ if ($name eq 'SubSNP') && /\);/;

    # TABLE SubSNPSeq3_p1_human (and Seq5 and p2,p3): change line_num tinyint to line_num smallint
    # *** TODO: How can we modify for different organisms?
    s/line_num tinyint/line_num smallint/ if $name =~ /SubSNPSeq[35]_p\d_human/;

    # Set the engine to $engine
    s/\)(.*);/\) ENGINE=$engine$1;/;

    $schema2 .= "$_\n";
  }

  return $schema2;
}

=head1 convert_constraint

    Convert table $name with constraint $constraint from MS SQL format to MySQL
    format

    USAGE

    convert_constraint($name,$constraint)

=cut

sub convert_constraint {

    my ( $name, $constraint ) = @_;
    my $constraint2 = '';
    my @lines2      = split "\n", $constraint;
    my @lines       = ();

    # Remove leading and trailing spaces and brackets
    for (@lines2) {
	s/^\s+//;
	s/\s+$//;
	push @lines, $_;
    }

    while (@lines) {
	$_ = shift @lines;
	s#[\[\]]##g;

	if (/ALTER TABLE (\w+)/) {
	    my $table_name = $1;

	  TABLE_LOOP: while ( my $line = shift @lines ) {

		if ( $line =~ /PRIMARY KEY/ ) {
		    my $line2 = shift @lines;    # Read '('
		    die "Unexpected format, no '(': $line2"
		      unless $line2 =~ /\(/;
		    $line2 = shift @lines;

		    chomp($line2);
		    die "Can't fine row name: $line2"
		      unless $line2 =~ /\[(\w+)\]/;
		    my $rows = $1;

		    # Read more rows
		    $line2 = shift @lines;
		    while ( $line2 !~ /\)/ ) {
			die "Can't fine row name: $line2"
			  unless $line2 =~ /\[(\w+)\]/;
			$rows .= ",$1";
			$line2 = shift @lines;
		    }
		    $rows = 'term(256)'
		      if $table_name eq 'SNPGlossary' and $rows eq 'term';
		    $constraint2 .=
		      "ALTER TABLE $table_name ADD PRIMARY KEY ($rows);\n";

# TABLE PopLine: replace PRIMARY KEY (pop_id,line_num) with UNIQUE INDEX (pop_id,line_num)
		    $constraint2 =~
s/PRIMARY KEY \(pop_id,line_num\)/UNIQUE INDEX \(pop_id,line_num\)/
		      if $table_name eq 'PopLine';

		}
		elsif ( $line =~ /DEFAULT/ ) {
		    next TABLE_LOOP
		      if ( $line =~ /getdate/ )
		      ;    # DEFAULT TIMESTAMP is automatic in MySQL

		    die "Can't find default value or row: $line"
		      unless $line =~ /DEFAULT \(([\w']+)\) FOR \[(\w+)\]/;
		    my $value = $1;
		    my $row   = $2;

		    # Determine the type of various columns
		    my %type = (
			is_major           => 'tinyint',
			ncbi_genome_tax_id => 'int',
			status             => 'char(1)',
			link_type          => 'varchar(3)',
			ploidy             => 'tinyint',
			inNonHuman         => 'char(1)'
		    );

		    die "ERROR: Can't find type for row \"$row\", table=$name"
		      unless defined $type{$row};

		    $constraint2 .=
"ALTER TABLE $table_name MODIFY $row $type{$row} DEFAULT $value;\n";

		}
		elsif ( $line =~ /FOREIGN KEY/ ) {
		    my $fkey = "$line (";
		    shift @lines;    # Skip "("

		    my $line2 = shift @lines;
		    while ( $line2 !~ /REFERENCES/ ) {
			$fkey .= $line2;
			$line2 = shift @lines;
		    }

		    $fkey .= $line2;
		    $line2 = shift @lines;
		    while ( $line2 !~ /\)/ ) {
			$fkey .= $line2;
			$line2 = shift @lines;
		    }
		    $fkey .= $line2;

		    $fkey =~ s#[\[\]]##g;    # Remove brackets
		    $fkey =~ s/,$//;

		    $fkey =~ s/CONSTRAINT //;
		    my $fkey_code = "ALTER TABLE $name ADD CONSTRAINT $fkey;";
		    $constraint2 .= "$fkey_code\n";

		}
		else {

		    # MySQL does not support the CHECK constraint at the moment

		    print
"-- WARNING: could not translate this ALTER TABLE action to MySQL: $line\n";
		    print
"-- WARNING: we should modify the schema for this \"CHECK\" statement\n"
		      if ( $line =~ /CHECK / );
		}
	    }    # TABLE_LOOP
	}    # if /^ALTER TABLE
    }    # while (@lines)
    return $constraint2;
}

sub convert_index {

    #
    # Convert table $name with schema $schema from MS SQL format to MySQL format
    #

    my $index  = shift;
    my $index2 = '';

    my @lines = split "\n", $index;
    for (@lines) {
	s#[\[\]]##g;

	if ( /CREATE/ && /INDEX (\w+)/ ) {
	    my $index_name = $1;

	    die "Can't find index name: '$_'" unless /ON (\w+)\(([\w, ]+)\)/;
	    my $table_name = $1;
	    my $rows       = $2;

	    # Set key lengths for some special cases
	    $rows =~ s/var_str/var_str(900)/;
	    $rows =~ s/obs_upp_fix/obs_upp_fix(512)/;
	    $rows =~ s/hgvs_name/hgvs_name(512)/;
	    $rows =~ s/allele/allele\(512\)/ if $index_name eq 'i_rsCtgMrna';
	    $rows = 'obs(900)' if $rows eq 'obs';

	    $index2 .=
	      "ALTER TABLE $table_name ADD INDEX $index_name ($rows);\n";
	}
    }

    return $index2;
}


#
# HELPER FUNCTIONS
#

# Print text underlines with a specified character
sub print_underline {
    my ( $word, $char ) = @_;
    $char = '-' unless defined $char;
    my $len = length($word);
    print "\n$word\n";
    for ( 1 .. $len ) { print $char}
    print "\n";
}


1;
