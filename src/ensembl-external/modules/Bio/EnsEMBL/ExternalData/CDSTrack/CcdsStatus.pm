package Bio::EnsEMBL::ExternalData::CDSTrack::CcdsStatus;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::CcdsStatusAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);

sub new {
  my($class,@args) = @_;

  my $self = bless {},$class;

  my ($dbid, $ccds_status, $adaptor) =  
	  rearrange([qw(DBID
	                CCDS_STATUS
                  ADAPTOR
			)],@args);
 
  $self->dbID         ( $dbid );
  $self->ccds_status  ( $ccds_status );
  $self->adaptor      ( $adaptor );
  
  return $self;
}

sub get_all_GroupVersions{
  my $self = shift;

  if( ! exists $self->{'_groupversion_array'} ) {
    if( defined $self->adaptor() ) {
      my $gva = $self->adaptor()->db()->get_GroupVersionAdaptor();
      my $groupversions = $gva->fetch_all_by_status( $self->ccds_status );
      $self->{'_groupversion_array'} = $groupversions;
    }
  }
  return $self->{'_groupversion_array'};

}


sub ccds_status {
  my $self = shift;
  $self->{'ccds_status'} = shift if ( @_ );
  return $self->{'ccds_status'};
}



1;
