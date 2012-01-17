package Bio::EnsEMBL::ExternalData::CDSTrack::Location;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::LocationAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);

sub new {
  my($class,@args) = @_;

  my $self = bless {},$class;

  my ($dbid, $exon_start, $exon_end, $adaptor) =  
	  rearrange([qw(DBID
	                EXON_START
                  EXON_END
                  ADAPTOR
			)],@args);
 
  $self->dbID        ( $dbid );
  $self->exon_start  ( $exon_start );
  $self->exon_end    ( $exon_end );
  $self->adaptor     ( $adaptor );
  
  return $self;
}

sub exon_start {
  my $self = shift;
  $self->{'chr_start'} = shift if ( @_ );
  return $self->{'chr_start'};
}

sub exon_end {
  my $self = shift;
  $self->{'chr_stop'} = shift if ( @_ );
  return $self->{'chr_stop'};
}

1;
