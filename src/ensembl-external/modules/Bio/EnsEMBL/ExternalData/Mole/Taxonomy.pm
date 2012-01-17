package Bio::EnsEMBL::ExternalData::Mole::Taxonomy;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::TaxonomyAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $entry_id, $adaptor, 
      $ncbi_tax_id) =  
	  rearrange([qw(DBID
	                ENTRY_ID 
                        ADAPTOR
                        NCBI_TAX_ID 
			)],@_);
  $self->dbID              ( $dbid );
  $self->entry_id          ( $entry_id );
  $self->adaptor           ( $adaptor );
  $self->ncbi_tax_id       ( $ncbi_tax_id );
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub ncbi_tax_id {
  my $self = shift;
  $self->{'ncbi_tax_id'} = shift if ( @_ );
  return $self->{'ncbi_tax_id'};
}

1;



