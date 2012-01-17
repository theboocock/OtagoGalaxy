package Bio::EnsEMBL::ExternalData::CDSTrack::Accession;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::AccessionAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);

sub new {
  my($class,@args) = @_;

  my $self = bless {},$class;

  my ($dbid, $transcript_stable_id, $transcript_version,
  $transcript_ncbi_id, $translation_stable_id, $translation_version, $translation_ncbi_id,
  $organization_id, $alive, $organization, $approval_authority, $adaptor) =  
	  rearrange([qw(DBID
	                TRANSCRIPT_STABLE_ID
                  TRANSCRIPT_VERSION
                  TRANSCRIPT_NCBI_ID
                  TRANSLATION_STABLE_ID
                  TRANSLATION_VERSION
                  TRANSLATION_NCBI_ID
                  ORGANIZATION_ID
                  ALIVE	
                  ORGANIZATION
                  APPROVAL_AUTHORITY
                  ADAPTOR
			)],@args);
 
  $self->dbID                  ( $dbid );
  $self->transcript_stable_id  ( $transcript_stable_id );
  $self->transcript_version    ( $transcript_version );
  $self->transcript_ncbi_id    ( $transcript_ncbi_id );
  $self->translation_stable_id ( $translation_stable_id );
  $self->translation_version   ( $translation_version );
  $self->translation_ncbi_id   ( $translation_ncbi_id );
  $self->organization_id       ( $organization_id );
  $self->alive                 ( $alive );
  $self->organization          ( $organization );
  $self->approval_authority    ( $approval_authority ); 
  $self->adaptor               ( $adaptor );
  
  return $self;
}

sub get_all_ccds_ids {
  my $self = shift;
  if( ! exists $self->{'_ccds_id'} ) {
    if( defined $self->adaptor() ) {
      my $gva = $self->adaptor()->db()->get_GroupVersionAdaptor();
      my @gv = @{$gva->fetch_all_by_accession($self->transcript_stable_id, $self->transcript_version)};
      my @ccds_id;
      foreach my $gv (@gv){
        push @ccds_id, $gv->get_ccds_id;
      }
      $self->{'_ccds_id'} = \@ccds_id;
    }
  }
  return $self->{'_ccds_id'};
}


sub get_all_GroupVersions {
  my $self = shift;

  if( ! exists $self->{'_groupversion_array'} ) {
    if( defined $self->adaptor() ) {
      my $gva = $self->adaptor()->db()->get_GroupVersionAdaptor();
      my $groupversions = $gva->fetch_all_by_accession( $self->transcript_stable_id, $self->transcript_version );
      $self->{'_groupversion_array'} = $groupversions;
    }
  }
  return $self->{'_groupversion_array'};
}


sub get_current_GroupVersion {
  my $self = shift;
  my $build_number = shift;
  
  throw("Require ncbi_build_number for get_current_GroupVersion")
         unless ($build_number);
  #need build number as an accession can have >1 current gv if it is on multiple builds

  if( ! exists $self->{'_groupversion_array'} ) {
    if( defined $self->adaptor() ) {
      my $gva = $self->adaptor()->db()->get_GroupVersionAdaptor();
      
      my $groupversions = $gva->fetch_all_current_by_accession( $self->transcript_stable_id, $self->transcript_version, $build_number );
      $self->{'_groupversion_array'} = $groupversions;
    }
  }
  return $self->{'_groupversion_array'};
}


#sub get_all_statuses { #do we only want current status? or status on a certain build?
#  my $self = shift;
#  if( ! exists $self->{'_status'} ) {
#    
#    my @status;
#    my @status_id = @{$self->adaptor->fetch_all_status_id($self->transcript_stable_id, $self->transcript_version)};
#
#    if( defined $self->adaptor() ) {
#      my $csa = $self->adaptor()->db()->get_CcdsStatusAdaptor();
#      
#      foreach my $stat_id (@status_id){
#        push @status, $csa->fetch_by_status_id($stat_id)->ccds_status;
#      }
#    }
#    $self->{'_status'} = \@status;
#  }
#  return $self->{'_status'};
#}
#
#
#sub get_all_Locations { #could bring back multiple sets of locations...
#  my $self = shift;
#  if( ! exists $self->{'_locations'} ) {
#    
#    print "in here\n";
#    
#    if( defined $self->adaptor() ) {
#      my $gva = $self->adaptor()->db()->get_GroupVersionAdaptor();
#      my @gv = @{$gva->fetch_all_by_accession($self->transcript_stable_id, $self->transcript_version)};
#      my @locations;
#      foreach my $gv (@gv){
#        print $gv->dbID."\n";
#        my @loc = @{$gv->get_all_Locations};
#        foreach my $l (@loc){
#          print $l->exon_start." - ".$l->exon_end."\n";
#        }
#        push @locations, [@{$gv->get_all_Locations}];
#      }
#      $self->{'_locations'} = \@locations;
#    }
#  }
#  return $self->{'_locations'};
#
#
#
#}


sub transcript_stable_id {
  my $self = shift;
  $self->{'nuc_acc'} = shift if ( @_ );
  return $self->{'nuc_acc'};
}

sub transcript_version {
  my $self = shift;
  $self->{'nuc_version'} = shift if ( @_ );
  return $self->{'nuc_version'};
}

sub transcript_ncbi_id {
  my $self = shift;
  $self->{'nuc_gi'} = shift if ( @_ );
  return $self->{'nuc_gi'};
}


sub translation_stable_id {
  my $self = shift;
  $self->{'prot_acc'} = shift if ( @_ );
  return $self->{'prot_acc'};
}

sub translation_version {
  my $self = shift;
  $self->{'prot_version'} = shift if ( @_ );
  return $self->{'prot_version'};
}

sub translation_ncbi_id {
  my $self = shift;
  $self->{'prot_gi'} = shift if ( @_ );
  return $self->{'prot_gi'};
}

sub organization_id {
  my $self = shift;
  $self->{'organization_uid'} = shift if ( @_ );
  return $self->{'organization_uid'};
}

sub alive {
  my $self = shift;
  $self->{'alive'} = shift if ( @_ );
  return $self->{'alive'};
}

sub organization {
  my $self = shift;
  $self->{'name'} = shift if ( @_ );
  return $self->{'name'};
}

sub approval_authority {
  my $self = shift;
  $self->{'approval_authority'} = shift if ( @_ );
  return $self->{'approval_authority'};
}

1;
