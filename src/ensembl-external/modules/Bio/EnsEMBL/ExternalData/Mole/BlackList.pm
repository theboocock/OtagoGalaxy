package Bio::EnsEMBL::ExternalData::Mole::BlackList;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::BlackListAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $entry_id, $adaptor, 
      $rating, $reason,
      $submitter, $submission_date) =  
	  rearrange([qw(DBID
	                ENTRY_ID 
                        ADAPTOR
                        RATING
                        REASON 
                        SUBMITTER
                        SUBMISSION_DATE
			)],@_);
  $self->dbID            ( $dbid );
  $self->entry_id        ( $entry_id );
  $self->adaptor         ( $adaptor );
  $self->rating          ( $rating );
  $self->reason          ( $reason );
  $self->submitter       ( $submitter );
  $self->submission_date ( $submission_date ); 
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub rating {
  my $self = shift;
  $self->{'rating'} = shift if ( @_ );
  return $self->{'rating'};
}

sub reason {
  my $self = shift;
  $self->{'reason'} = shift if ( @_ );
  return $self->{'reason'};
}

sub submitter {
  my $self = shift;
  $self->{'submitter'} = shift if ( @_ );
  return $self->{'submitter'};
}

sub submission_date {
  my $self = shift;
  $self->{'submission_date'} = shift if ( @_ );
  return $self->{'submission_date'};
}

1;

