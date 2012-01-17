package Bio::EnsEMBL::ExternalData::Mole::DBSQL::DescriptionAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Description;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);

sub _tables {
  my $self = shift;
  return (['description' , 'd']);
}

sub _columns {
  my $self = shift;
  return ( 'd.entry_id', 'd.description');
}

sub fetch_by_dbID {
  my $self = shift;
  my $id = shift;
  my $constraint = "d.entry_id = '$id'";
  my ($description_obj) = @{ $self->generic_fetch($constraint) };
  return $description_obj;
}

sub fetch_by_Entry {
  my $self = shift;
  my $entry = shift;
  my $sth = $self->prepare(
            "SELECT a.accession_id ".
            "FROM accession a ".
            "WHERE a.entry_id = ?");
  $sth->bind_param(1, $entry->dbID, SQL_INTEGER);
  $sth->execute();
  my $id = $sth->fetchrow();
  $sth->finish();

  my $description_object = $self->fetch_by_dbID($id);
  return $description_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "d.entry_id = '$entry_id'";
  my ($description_obj) = @{ $self->generic_fetch($constraint) };
  return $description_obj;
}

sub fetch_by_description {
  my $self = shift;
  my $description = shift;
  my $constraint = "d.description = '$description'";
  my ($description_obj) = @{ $self->generic_fetch($constraint) };
  return $description_obj;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my @out;
  my ( $entry_id, $description );
  $sth->bind_columns( \$entry_id, \$description );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::Description->new(
              -dbID           => $entry_id,
              -description    => $description, 
              -adaptor        => $self
              );
  }
  return \@out;
}


1;

