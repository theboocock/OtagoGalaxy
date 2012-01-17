package Bio::EnsEMBL::ExternalData::Mole::DBXref;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBXrefAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $adaptor, $entry_id, $database_id,
      $primary_id, $secondary_id, $tertiary_id,
      $quaternary_id ) = 
	  rearrange([qw(DBID
                        ADAPTOR
                        ENTRY_ID
                        DATABASE_ID
                        PRIMARY_ID
                        SECONDARY_ID
                        TERTIARY_ID
                        QUATERNARY_ID      
			)],@_); 

  $self->dbID              ( $dbid );
  $self->adaptor           ( $adaptor );
  $self->entry_id          ( $entry_id ); 
  $self->database_id       ( $database_id );
  $self->primary_id        ( $primary_id );
  $self->secondary_id      ( $secondary_id )  if (defined $secondary_id);
  $self->tertiary_id       ( $tertiary_id )   if (defined $tertiary_id);
  $self->quaternary_id     ( $quaternary_id ) if (defined $quaternary_id);
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub database_id {
  my $self = shift;
  $self->{'database_id'} = shift if ( @_ );
  return $self->{'database_id'};
}

sub primary_id {
  my $self = shift;
  $self->{'primary_id'} = shift if ( @_ );
  return $self->{'primary_id'};
}

sub secondary_id {
  my $self = shift;
  $self->{'secondary_id'} = shift if ( @_ );
  return $self->{'secondary_id'};
}

sub tertiary_id {
  my $self = shift;
  $self->{'tertiary_id'} = shift if ( @_ );
  return $self->{'tertiary_id'};
}

sub quaternary_id {
  my $self = shift;
  $self->{'quaternary_id'} = shift if ( @_ );
  return $self->{'quaternary_id'};
}
1;



