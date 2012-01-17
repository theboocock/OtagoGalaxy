package Bio::EnsEMBL::ExternalData::CDSTrack::Ccds;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::CcdsAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);

sub new {
  my($class,@args) = @_;

  my $self = bless {},$class;

  my ($dbid, $group_id, $latest_version, $adaptor) =  
	  rearrange([qw(
	                DBID
                  GROUP_ID
                  LATEST_VERSION
                  ADAPTOR
			)],@args);
 
  $self->dbID           ( $dbid );
  $self->group_id       ( $group_id );
  $self->latest_version ( $latest_version );
  $self->adaptor        ( $adaptor );
  
  return $self;
}

sub get_all_GroupVersions{
  my $self = shift;

  if( ! exists $self->{'_groupversion_array'} ) {
    if( defined $self->adaptor() ) {
      my $gva = $self->adaptor()->db()->get_GroupVersionAdaptor();
      my $groupversions = $gva->fetch_all_by_CCDS_ID( $self->ccds_id );
      $self->{'_groupversion_array'} = $groupversions;
    }
  }
  return $self->{'_groupversion_array'};

}

sub ccds_id {
  my $self = shift;
  return $self->dbID;
}

sub group_id {
  my $self = shift;
  $self->{'group_id'} = shift if ( @_ );
  return $self->{'group_id'};
}

sub latest_version {
  my $self = shift;
  $self->{'latest_version'} = shift if ( @_ );
  return $self->{'latest_version'};
}


1;
