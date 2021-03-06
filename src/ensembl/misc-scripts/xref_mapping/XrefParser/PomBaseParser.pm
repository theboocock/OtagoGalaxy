package XrefParser::PomBaseParser;

use strict;
use POSIX qw(strftime);
use File::Basename;

use base qw( XrefParser::BaseParser );

# --------------------------------------------------------------------------------
# Parse command line and run if being run directly

sub run {

  my $self = shift;
  my $source_id = shift;
  my $species_id = shift;
  my $files_ref  = shift;
  my $rel_file   = shift;
  my $verbose = shift;

  my $file = @{$files_ref}[0];

  if(!defined($source_id)){
    $source_id = XrefParser::BaseParser->get_source_id_for_filename($file);
  }
  if(!defined($species_id)){
    $species_id = XrefParser::BaseParser->get_species_id_for_filename($file);
  }
  
  my $gene_source_id = XrefParser::BaseParser->get_source_id_for_source_name("PomBase_GENE");
  my $transcript_source_id = XrefParser::BaseParser->get_source_id_for_source_name("PomBase_TRANSCRIPT");

  my $pombase_io = $self->get_filehandle($file);

  if ( !defined $pombase_io ) {
    print STDERR "ERROR: Could not open $file\n";
    return 1;    # 1 is an error
  }

  my $xref_count =0;
  my $syn_count =0;

  while ( $_ = $pombase_io->getline() ) {

    chomp;

    if ($_ =~ /^([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) {
	    
	    my @line = split(m/\t/ms, $_);
	    my ($pombase_id, $name, $info_type, $biotype, $external_db_source, $desc, $ensembl_object_type, $synonyms) = undef;
	    
	    $pombase_id          = $line[0];
	    $name                = $line[1];
	    $info_type           = $line[2];
	    $biotype             = $line[3];
            $external_db_source  = $line[4];
	    $desc                = $line[5];
	    $ensembl_object_type = $line[6];
	    
	    if (scalar @line == 8) {
	        $synonyms = $line[7];
	    }
	    # parse the lines corresponding to the gene entries
	    # and filter out lines corresponding to the CDS for example
	   
            #print "$ensembl_object_type\n"; 
	    if ($ensembl_object_type eq 'Gene') {
	        my $ensembl_xref_id = $self->add_xref($pombase_id,"",$name,$desc,$gene_source_id,$species_id,$info_type);
	        $self->add_direct_xref($ensembl_xref_id, $pombase_id, $ensembl_object_type, $info_type);
	    } elsif ($ensembl_object_type eq 'Transcript') {
	        my $ensembl_xref_id = $self->add_xref($pombase_id,"",$name,$desc,$transcript_source_id,$species_id,$info_type);
	        $self->add_direct_xref($ensembl_xref_id, $pombase_id, $ensembl_object_type, $info_type);
	    }
	    
	    $xref_count++;
	    if ($synonyms) {
	   	 my (@syn) = split(/,/,$synonyms);
	    	foreach my $synonym (@syn){
			    if ($verbose) {
			        print STDERR "adding synonym, $synonym\n";
			    }
			    $self->add_to_syn($pombase_id, $gene_source_id, $synonym, $species_id);
			    $syn_count++;
		    }
	    }
    } else {
	    if ($verbose) {
	        print STDERR "failed to parse line, $_\n\n";
	    }
    }
  }

  $pombase_io->close();

  print $xref_count." PomBase Xrefs added with $syn_count synonyms\n" if($verbose);
  return 0; #successful
}

1;
