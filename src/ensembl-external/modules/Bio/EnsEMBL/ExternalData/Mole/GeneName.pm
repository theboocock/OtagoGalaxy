package Bio::EnsEMBL::ExternalData::Mole::GeneName;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::GeneNameAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $entry_id, $adaptor, 
      $name, $name_type) =  
	  rearrange([qw(DBID
	                ENTRY_ID 
                        ADAPTOR
                        NAME
                        NAME_TYPE 
			)],@_);
  $self->dbID      ( $dbid );
  $self->entry_id  ( $entry_id );
  $self->adaptor   ( $adaptor );
  $self->name      ( $name );
  $self->name_type ( $name_type );
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub name {
  my $self = shift;
  $self->{'name'} = shift if ( @_ );
  return $self->{'name'};
}

sub name_type {
  my $self = shift;
  $self->{'name_type'} = shift if ( @_ );
  return $self->{'name_type'};
}

1;



