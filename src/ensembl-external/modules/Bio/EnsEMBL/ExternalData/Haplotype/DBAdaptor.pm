use strict;

package Bio::EnsEMBL::ExternalData::Haplotype::DBAdaptor;

use vars qw(@ISA);
use Bio::EnsEMBL::DBSQL::DBAdaptor;

@ISA = qw(Bio::EnsEMBL::DBSQL::DBAdaptor);

sub get_available_adaptors{
  my %pairs = ('Haplotype' => 'Bio::EnsEMBL::ExternalData::Haplotype::HaplotypeAdaptor');
  return (\%pairs);
}
 

1;
