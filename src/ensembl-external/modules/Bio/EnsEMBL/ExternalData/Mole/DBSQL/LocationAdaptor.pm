package Bio::EnsEMBL::ExternalData::Mole::DBSQL::LocationAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Location;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['location' , 'lcn']);
}

sub _columns {
  my $self = shift;
  return ( 'lcn.entry_id', 'lcn.flat_file',
           'lcn.file_offset', 'lcn.blastdbtracking_id');
}

sub fetch_by_Entry {
  my $self = shift;
  my $entry = shift;

  my $location_object = $self->fetch_by_entry_id($entry->dbID);
  return $location_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "lcn.entry_id = '$entry_id'";
  my ($location_obj) = @{ $self->generic_fetch($constraint) };
  return $location_obj;
}

sub fetch_by_flat_file {
  my ($self, $flat_file) = @_;
  my $constraint = "lcn.flat_file = '$flat_file'";
  my ($location_obj) = @{ $self->generic_fetch($constraint) };
  return $location_obj;
}

sub fetch_by_blastdbtracking_id {
  my ($self, $blastdbtracking_id) = @_;
  my $constraint = "lcn.blastdbtracking_id = '$blastdbtracking_id'";
  my ($location_obj) = @{ $self->generic_fetch($constraint) };
  return $location_obj;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my @out;
  my ( $entry_id, $flat_file, $file_offset, $blastdbtracking_id );
  $sth->bind_columns( \$entry_id, \$flat_file, \$file_offset, \$blastdbtracking_id );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::Location->new(
              -entry_id           => $entry_id,
              -adaptor            => $self,
              -flat_file          => $flat_file,
              -file_offset        => $file_offset,
              -blastdbtracking_id => $blastdbtracking_id,
              );
  }
  return \@out;
}


1;

