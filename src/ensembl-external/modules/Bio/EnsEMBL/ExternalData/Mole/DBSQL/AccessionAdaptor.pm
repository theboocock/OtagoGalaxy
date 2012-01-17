package Bio::EnsEMBL::ExternalData::Mole::DBSQL::AccessionAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Accession;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['accession' , 'a']);
}

sub _columns {
  my $self = shift;
  return ( 'a.accession_id', 'a.entry_id',
           'a.accession', 'a.qualifier');
}

sub fetch_by_dbID {
  my $self = shift;
  my $id = shift;
  my $constraint = "a.accession_id = '$id'";
  my ($accession_obj) = @{ $self->generic_fetch($constraint) };
  return $accession_obj;
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
  my $acc_id = $sth->fetchrow();
  $sth->finish();

  my $accession_object = $self->fetch_by_dbID($acc_id);
  return $accession_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "a.entry_id = '$entry_id'";
  my ($accession_obj) = @{ $self->generic_fetch($constraint) };
  return $accession_obj;
}

sub fetch_by_accession {
  my ($self, $acc) = @_;
  my $constraint = "a.accession = '$acc'";
  my ($accession_obj) = @{ $self->generic_fetch($constraint) };
  return $accession_obj;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my @out;
  my ( $acc_id, $entry_id, $accession, $qualifier );
  $sth->bind_columns( \$acc_id, \$entry_id, \$accession, \$qualifier );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::Accession->new(
              -dbID           => $acc_id,
              -entry_id       => $entry_id,
              -adaptor        => $self,
              -accession      => $accession,
              -qualifier      => $qualifier,
              );
  }
  return \@out;
}


1;

