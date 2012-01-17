package Bio::EnsEMBL::ExternalData::Mole::Keyword;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::KeywordAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $entry_id, $adaptor, 
      $keyword) =  
	  rearrange([qw(DBID
	                ENTRY_ID 
                        ADAPTOR
                        KEYWORD
			)],@_);
  $self->dbID     ( $dbid );
  $self->entry_id ( $entry_id );
  $self->adaptor  ( $adaptor );
  $self->keyword  ( $keyword );
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub keyword {
  my $self = shift;
  $self->{'keyword'} = shift if ( @_ );
  return $self->{'keyword'};
}

1;



