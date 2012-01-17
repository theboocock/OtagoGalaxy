package Bio::EnsEMBL::ExternalData::Mole::DBSQL::SequenceAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Sequence;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['sequence' , 'seq']);
}

sub _columns {
  my $self = shift;
  return ( 'seq.entry_id',
           'seq.split_counter', 'seq.sequence');
}

sub fetch_by_Entry {
  my $self = shift;
  my $entry = shift;

  my $sequence_object = $self->fetch_by_entry_id($entry->dbID);
  return $sequence_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "seq.entry_id = '$entry_id'";
  my ($sequence_obj) = @{ $self->generic_fetch($constraint) };
  return $sequence_obj;
}

sub fetch_by_sequence {
  my ($self, $seq) = @_;
  my $constraint = "seq.sequence = '$seq'";
  my ($sequence_obj) = @{ $self->generic_fetch($constraint) };
  return $sequence_obj;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my @out;
  my ( $entry_id, $split_counter, $sequence );
  $sth->bind_columns( \$entry_id, \$split_counter, \$sequence );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::Sequence->new(
              -entry_id       => $entry_id,
              -adaptor        => $self,
              -split_counter  => $split_counter,
              -sequence       => $sequence,
              );
  }
  return \@out;
}


1;

