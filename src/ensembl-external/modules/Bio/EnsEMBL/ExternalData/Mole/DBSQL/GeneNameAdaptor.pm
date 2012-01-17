package Bio::EnsEMBL::ExternalData::Mole::DBSQL::GeneNameAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::GeneName;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['genename' , 'g']);
}

sub _columns {
  my $self = shift;
  return ( 'g.genename_id', 'g.entry_id',
           'g.name', 'g.name_type');
}

sub fetch_by_dbID {
  my $self = shift;
  my $id = shift;
  my $constraint = "g.genename_id = '$id'";
  my ($genename_obj) = @{ $self->generic_fetch($constraint) };
  return $genename_obj;
}

sub fetch_by_Entry {
  my $self = shift;
  my $entry = shift;
  my $sth = $self->prepare(
            "SELECT g.genename_id ".
            "FROM genename g ".
            "WHERE g.entry_id = ?");
  $sth->bind_param(1, $entry->dbID, SQL_INTEGER);
  $sth->execute();
  my $gname_id = $sth->fetchrow();
  $sth->finish();

  my $genename_object = $self->fetch_by_dbID($gname_id);
  return $genename_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "g.entry_id = '$entry_id'";
  my ($genename_obj) = @{ $self->generic_fetch($constraint) };
  return $genename_obj;
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;

  #get all entry_ids with this name
  $sth = $self->prepare(
         "SELECT entry_id ".
         "FROM genename ".
         "WHERE name = '$name' ");
  $sth->execute();
  my @array = @{$sth->fetchall_arrayref()};
  my @entry_ids = map {$_->[0]} @array;
  my $entries = $self->fetch_all_by_dbID_list(\@entry_ids);

  return $entries;
}

sub fetch_by_name_type {
  my $self = shift;
  my $name_type = shift;

  #get all entry_ids with this name_type
  $sth = $self->prepare(
         "SELECT entry_id ".
         "FROM genename_type ".
         "WHERE name_type = '$name_type' ");
  $sth->execute();
  my @array = @{$sth->fetchall_arrayref()};
  my @entry_ids = map {$_->[0]} @array;
  my $entries = $self->fetch_all_by_dbID_list(\@entry_ids);

  return $entries;
}

sub fetch_all_by_dbID_list {
  my ($self,$id_list_ref) = @_;

  if(!defined($id_list_ref) || ref($id_list_ref) ne 'ARRAY') {
    croak("kill object id list reference argument is required");
  }

  return [] if(!@$id_list_ref);

  my @out;
  #construct a constraint like 't1.table1_id = 123'
  my @tabs = $self->_tables;
  my ($name, $syn) = @{$tabs[0]};

  # mysql is faster and we ensure that we do not exceed the max query size by
  # splitting large queries into smaller queries of 200 ids
  my $max_size = 200;
  my @id_list = @$id_list_ref;

  while(@id_list) {
    my @ids;
    if(@id_list > $max_size) {
      @ids = splice(@id_list, 0, $max_size);
    } else {
      @ids = splice(@id_list, 0);
    }

    my $id_str;
    if(@ids > 1)  {
      $id_str = " IN (" . join(',', @ids). ")";
    } else {
      $id_str = " = " . $ids[0];
    }

    my $constraint = "${syn}.${name}_id $id_str";
    push @out, @{$self->generic_fetch($constraint)};
  }
  return \@out;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my @out;
  my ( $genename_id, $entry_id, $name, $name_type );
  $sth->bind_columns( \$genename_id, \$entry_id, \$name, \$name_type );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::GeneName->new(
              -dbID           => $genename_id,
              -entry_id       => $entry_id,
              -adaptor        => $self,
              -name           => $name,
              -name_type      => $name_type,
              );
  }
  return \@out;
}


1;

