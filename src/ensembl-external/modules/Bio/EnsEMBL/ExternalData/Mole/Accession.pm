package Bio::EnsEMBL::ExternalData::Mole::Accession;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::AccessionAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $entry_id, $adaptor, 
      $accession, $qualifier) =  
	  rearrange([qw(DBID
	                ENTRY_ID 
                        ADAPTOR
                        ACCESSION
                        QUALIFIER 
			)],@_);
  $self->dbID              ( $dbid );
  $self->entry_id          ( $entry_id );
  $self->adaptor           ( $adaptor );
  $self->accession         ( $accession );
  $self->qualifier         ( $qualifier );
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub accession {
  my $self = shift;
  $self->{'accession'} = shift if ( @_ );
  return $self->{'accession'};
}

sub qualifier {
  my $self = shift;
  $self->{'qualifier'} = shift if ( @_ );
  return $self->{'qualifier'};
}

1;



