package Bio::EnsEMBL::ExternalData::Mole::Sequence;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::SequenceAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {

  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($entry_id, $adaptor, 
      $split_counter, $sequence) =  
	  rearrange([qw(ENTRY_ID 
                        ADAPTOR
                        SPLIT_COUNTER
                        SEQUENCE 
			)],@_);
  $self->entry_id        ( $entry_id );
  $self->adaptor         ( $adaptor );
  $self->split_counter   ( $split_counter );
  $self->sequence        ( $sequence );
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub split_counter {
  my $self = shift;
  $self->{'split_counter'} = shift if ( @_ );
  return $self->{'split_counter'};
}

sub sequence {
  my $self = shift;
  $self->{'sequence'} = shift if ( @_ );
  return $self->{'sequence'};
}

1;



