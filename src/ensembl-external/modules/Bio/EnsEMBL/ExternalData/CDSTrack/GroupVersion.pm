package Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::GroupVersionAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my($class,@args) = @_;

  my $self = bless {},$class;

  my ($dbid, $group_id, $group_version, $ncbi_build_number,
  $first_ncbi_build_version, $last_ncbi_build_version, $ncbi_gene_id,
  $location_count, $ccds_status_val_id, $ccds_version, $was_public, 
  $current_version, $tax_id, $chromosome, $strand, $adaptor) =
	  rearrange([qw(DBID
	                GROUP_ID
                  GROUP_VERSION
                  NCBI_BUILD_NUMBER
                  FIRST_NCBI_BUILD_VERSION
                  LAST_NCBI_BUILD_VERSION
                  NCBI_GENE_ID
                  LOCATION_COUNT
                  CCDS_STATUS_VAL_ID
                  CCDS_VERSION
                  WAS_PUBLIC	
                  CURRENT_VERSION
                  TAX_ID
                  CHROMOSOME
                  STRAND
                  ADAPTOR
			)],@args);
 
  $self->dbID                     ( $dbid );
  $self->group_id                 ( $group_id );
  $self->group_version            ( $group_version );
  $self->ncbi_build_number        ( $ncbi_build_number );
  $self->first_ncbi_build_version ( $first_ncbi_build_version );
  $self->last_ncbi_build_version  ( $last_ncbi_build_version );
  $self->ncbi_gene_id             ( $ncbi_gene_id );
  $self->location_count           ( $location_count );
  $self->ccds_status_val_id       ( $ccds_status_val_id ); 
  $self->ccds_version             ( $ccds_version );
  $self->was_public               ( $was_public );
  $self->current_version          ( $current_version );
  $self->tax_id                   ( $tax_id );
  $self->chromosome               ( $chromosome );
  $self->strand                   ( $strand ); 
  $self->adaptor                  ( $adaptor );
  
  return $self;
}

sub get_all_Accessions {
  my $self = shift;

  if( ! exists $self->{'_accession_array'} ) {
    if( defined $self->adaptor() ) {
      my $aa = $self->adaptor()->db()->get_AccessionAdaptor();
      my $accessions = $aa->fetch_all_by_GroupVersion( $self );
      $self->{'_accession_array'} = $accessions;
    }
  }
  return $self->{'_accession_array'};
}

sub get_all_Locations { #for XY will only return X coords
  my $self = shift;
  print "Getting all locations for group_version_uid '".$self->group_id."'\n";

  if( ! exists $self->{'_location_array'} ) {
    if( defined $self->adaptor() ) {
      my $la = $self->adaptor()->db()->get_LocationAdaptor();
      my $locations = $la->fetch_all_by_GroupVersion( $self );
      $self->{'_location_array'} = $locations;
      print "Stored ".scalar(@$locations)." locations  for ".$self->group_id."\n";
    }
  } else {
    print "LOCATION ARRAY EXISTS\n";
  }
  return $self->{'_location_array'};
}

sub get_ccds_uid {
  my $self = shift;
  my $ccds_id;

  if( ! exists $self->{'_ccds_uid'} ) {
    if( defined $self->adaptor() ) {
      my $ca = $self->adaptor()->db()->get_CcdsAdaptor();
      if (defined $ca->fetch_by_GroupVersion($self)){
        ($ccds_id) = $ca->fetch_by_GroupVersion($self)->ccds_id;
      }
    }
  } else {
    $ccds_id = $self->{'_ccds_uid'};
  }
  
  $ccds_id =~ s/CCDS//;
  $ccds_id =~ s/\.\d+//;
  $self->{'_ccds_uid'} = $ccds_id;
  return $self->{'_ccds_uid'};
}
sub get_ccds_id {
  my $self = shift;
  if( ! exists $self->{'_ccds_id'}  || exists $self->{'_ccds_id'} && $self->{'_ccds_id'} !~ /^CCDS/) {
    if( defined $self->adaptor() ) {
      my $ca = $self->adaptor()->db()->get_CcdsAdaptor();
      if (defined $ca->fetch_by_GroupVersion($self)){
        my ($ccds_id) = $ca->fetch_by_GroupVersion($self)->ccds_id;
        $ccds_id = join "", 'CCDS', $ccds_id, '.', $self->ccds_version;
        $self->{'_ccds_id'} = $ccds_id;
      }
    }
  }
  return $self->{'_ccds_id'};
}

sub get_all_Interpretations {

  my $self = shift;
  my $interpretation_subtype = shift; # eg 'Translation exception'

  if( ! exists $self->{'interpretations' } ) {
    if(!$self->adaptor() ) {
      return [];
    }

    my $interpretation_adaptor = $self->adaptor->db->get_InterpretationAdaptor();
    $self->{'interpretations'} = $interpretation_adaptor->fetch_all_by_GroupVersion_and_CcdsID($self,$self->get_ccds_uid);
  }

  if( defined $interpretation_subtype) {
    my @results = grep { uc($_->interpretation_subtype()) eq uc($interpretation_subtype) }
      @{$self->{'interpretations'}};
    return\@ results;
  } else {
    return $self->{'interpretations'};
  }

}

sub get_Public_Note {
  my $self = shift;

  if( ! exists $self->{'public_note' } ) {
    if(!$self->adaptor() ) {
      return [];
    }

    my $interpretation_adaptor = $self->adaptor->db->get_InterpretationAdaptor();
    $self->{'public_note'} = $interpretation_adaptor->fetch_PublicNote_by_CcdsID($self->get_ccds_uid);
  }

  return $self->{'public_note'};

}

sub get_status {
  my $self = shift;
  if( ! exists $self->{'_status'} ) {
    if( defined $self->adaptor() ) {
      my $csa = $self->adaptor()->db()->get_CcdsStatusAdaptor();
      my ($status) = $csa->fetch_by_status_id($self->ccds_status_val_id)->ccds_status;
      $self->{'_status'} = $status;
    }
  }
  return $self->{'_status'};
}

sub group_id {
  my $self = shift;
  $self->{'group_uid'} = shift if ( @_ );
  return $self->{'group_uid'};
}

sub group_version {
  my $self = shift;
  $self->{'version'} = shift if ( @_ );
  return $self->{'version'};
}

sub ncbi_build_number {
  my $self = shift;
  $self->{'ncbi_build_number'} = shift if ( @_ );
  return $self->{'ncbi_build_number'};
}
sub first_ncbi_build_version {
  my $self = shift;
  $self->{'first_ncbi_build_version'} = shift if ( @_ );
  return $self->{'first_ncbi_build_version'};
}

sub last_ncbi_build_version {
  my $self = shift;
  $self->{'last_ncbi_build_version'} = shift if ( @_ );
  return $self->{'last_ncbi_build_version'};
}

sub ncbi_gene_id {
  my $self = shift;
  $self->{'gene_id'} = shift if ( @_ );
  return $self->{'gene_id'};
}

sub location_count {
  my $self = shift;
  $self->{'location_count'} = shift if ( @_ );
  return $self->{'location_count'};
}

sub ccds_status_val_id {
  my $self = shift;
  $self->{'ccds_status_val_uid'} = shift if ( @_ );
  return $self->{'ccds_status_val_uid'};
}

sub ccds_version {
  my $self = shift;
  $self->{'ccds_version'} = shift if ( @_ );
  return $self->{'ccds_version'};
}

sub was_public {
  my $self = shift;
  $self->{'was_public'} = shift if ( @_ );
  return $self->{'was_public'};
}

sub current_version {
  my $self = shift;
  $self->{'current_version'} = shift if ( @_ );
  return $self->{'current_version'};
}

sub tax_id {
  my $self = shift;
  $self->{'tax_id'} = shift if ( @_ );
  return $self->{'tax_id'};
}

sub chromosome {
  my $self = shift;
  $self->{'chromosome'} = shift if ( @_ );
  return $self->{'chromosome'};
}

sub strand {
  my $self = shift;
  $self->{'strand'} = shift if ( @_ );
  return $self->{'strand'};
}



1;
