package Bio::EnsEMBL::ExternalData::Mole::DBSQL::EntryArchiveAdaptor; 

# Copied from Entry.pm but has less functionality
# eg. accession and dbxref is not supported
# Also fewer fetch functions
#

use strict;
use Bio::EnsEMBL::ExternalData::Mole::EntryArchive;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['entry' , 'e']);
}

sub _columns {
  my $self = shift;
  return ( 'e.entry_id', 'e.accession_version',
           'e.name', 'e.topology', 'e.molecule_type',
           'e.data_class', 'e.tax_division',
           'e.sequence_length');
}

sub fetch_by_dbID {
  my $self = shift;
  my $entryid = shift;
  my $constraint = "e.entry_id = '$entryid'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_accession_version {
  my $self = shift;
  my $acc = shift;
  my $constraint = "e.accession_version = '$acc'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "e.name = '$name'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}


sub _objs_from_sth {
  my ($self, $sth) = @_;


  my @out;
  my ( $entry_id, $accession_version, $name,
       $topology, $molecule_type, $data_class,
       $tax_division, $sequence_length );
  $sth->bind_columns( \$entry_id, \$accession_version, \$name, 
                      \$topology, \$molecule_type, \$data_class,
                      \$tax_division, \$sequence_length);

  while($sth->fetch()) {
    my $desc_obj = $self->db->get_DescriptionAdaptor->fetch_by_entry_id($entry_id);
    my $seq_obj = $self->db->get_SequenceAdaptor->fetch_by_entry_id($entry_id);
    my $taxonomy_obj = $self->db->get_TaxonomyAdaptor->fetch_by_entry_id($entry_id);
    push @out, Bio::EnsEMBL::ExternalData::Mole::EntryArchive->new(
              -dbID               => $entry_id,
              -accession_version  => $accession_version,
              -name               => $name,
              -topology           => $topology,
              -molecule_type      => $molecule_type,
              -data_class         => $data_class,
              -tax_division       => $tax_division,
              -sequence_length    => $sequence_length,
              -description_obj    => $desc_obj,
              -sequence_obj       => $seq_obj,
              -taxonomy_obj       => $taxonomy_obj,
              );
  }
  return \@out;
}


1;

