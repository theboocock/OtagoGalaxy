package Bio::EnsEMBL::ExternalData::Mole::Description;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DescriptionAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $description, $adaptor
      ) =  
	  rearrange([qw(DBID
                        DESCRIPTION
                        ADAPTOR
			)],@_);

  $self->dbID          ( $dbid );
  $self->description   ( $description ) if (defined $description);
  $self->adaptor       ( $adaptor );
  return $self; # success - we hope!
}

sub description {
  my $self = shift;
  $self->{'description'} = shift if ( @_ );
  return $self->{'description'};
}

1;



