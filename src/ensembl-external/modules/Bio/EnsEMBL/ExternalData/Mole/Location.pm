package Bio::EnsEMBL::ExternalData::Mole::Location;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::LocationAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($entry_id, $adaptor, 
      $flat_file, $file_offset,
      $blastdbtracking_id) =  
	  rearrange([qw(ENTRY_ID 
                        ADAPTOR
                        FLAT_FILE
                        FILE_OFFSET 
                        BLASTDBTRACKING_ID
			)],@_);
  $self->entry_id           ( $entry_id );
  $self->adaptor            ( $adaptor );
  $self->flat_file          ( $flat_file );
  $self->file_offset        ( $file_offset );
  $self->blastdbtracking_id ( $blastdbtracking_id );
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub flat_file {
  my $self = shift;
  $self->{'flat_file'} = shift if ( @_ );
  return $self->{'flat_file'};
}

sub file_offset {
  my $self = shift;
  $self->{'file_offset'} = shift if ( @_ );
  return $self->{'file_offset'};
}

sub blastdbtracking_id {
  my $self = shift;
  $self->{'blastdbtracking_id'} = shift if ( @_ );
  return $self->{'blastdbtracking_id'};
}

1;



