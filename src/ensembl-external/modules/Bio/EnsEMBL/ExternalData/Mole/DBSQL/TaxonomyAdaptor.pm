package Bio::EnsEMBL::ExternalData::Mole::DBSQL::TaxonomyAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Taxonomy;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['taxonomy' , 't']);
}

sub _columns {
  my $self = shift;
  return ( 't.taxonomy_id', 't.entry_id',
           't.ncbi_tax_id');
}

sub fetch_by_dbID {
  my $self = shift;
  my $id = shift;
  my $constraint = "t.taxonomy_id = '$id'";
  my ($accession_obj) = @{ $self->generic_fetch($constraint) };
  return $accession_obj;
}

sub fetch_by_Entry {
  my $self = shift;
  my $entry = shift;
  my $sth = $self->prepare(
            "SELECT t.taxonomy_id ".
            "FROM taxonomy t ".
            "WHERE t.entry_id = ?");
  $sth->bind_param(1, $entry->dbID, SQL_INTEGER);
  $sth->execute();
  my $id = $sth->fetchrow();
  $sth->finish();

  my $taxonomy_object = $self->fetch_by_dbID($id);
  return $taxonomy_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "t.entry_id = '$entry_id'";
  my ($taxonomy_obj) = @{ $self->generic_fetch($constraint) };
  return $taxonomy_obj;
}

sub fetch_by_ncbi_tax_id {
  my ($self, $taxid) = @_;
  my $constraint = "t.ncbi_tax_id = '$taxid'";
  my ($ncbi_tax_id_obj) = @{ $self->generic_fetch($constraint) };
  return $ncbi_tax_id_obj;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my @out;
  my ( $tax_id, $entry_id, $ncbi_tax_id );
  $sth->bind_columns( \$tax_id, \$entry_id, \$ncbi_tax_id );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::Taxonomy->new(
              -dbID           => $tax_id,
              -entry_id       => $entry_id,
              -adaptor        => $self,
              -ncbi_tax_id    => $ncbi_tax_id,
              );
  }
  return \@out;
}


1;

