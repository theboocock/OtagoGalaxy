package Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBXrefAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::DBXref;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['dbxref' , 'dbxrf']);
}

sub _columns {
  my $self = shift;
  return ( 'dbxrf.dbxref_id', 'dbxrf.entry_id',
           'dbxrf.database_id', 'dbxrf.primary_id',
           'dbxrf.secondary_id', 'dbxrf.tertiary_id',
           'dbxrf.quaternary_id');
}

sub fetch_by_dbID {
  my ($self, $id) = @_;
  my $constraint = "dbxrf.dbxref_id = '$id'";
  my ($dbxref_obj) = @{ $self->generic_fetch($constraint) };
  return $dbxref_obj;
}

sub fetch_all_by_Entry {
  my $self = shift;
  my $entry = shift;
  my $sth = $self->prepare(
            "SELECT dbxrf.dbxref_id ".
            "FROM dbxref dbxrf ".
            "WHERE dbxrf.entry_id = ?");
  $sth->bind_param(1, $entry->dbID, SQL_INTEGER);
  $sth->execute();
  my @dbxrefids;
  while (my $id = $sth->fetchrow) {
    push @dbxrefids, $id;
  }
  $sth->finish();

  #my @obj_ids = map {$_->[0]} @dbxrefids;
  my @obj_ids = @dbxrefids;
  my @dbxrefs;
  foreach my $id (@obj_ids) {
    my $dbxref_object = $self->fetch_by_dbID($id);
    push @dbxrefs, $dbxref_object;
  }
  return \@dbxrefs;
}

sub fetch_all_by_entry_id {
  my ($self, $id) = @_;

  my $sth = $self->prepare(
                  "SELECT dbxrf.dbxref_id ".
                  "FROM dbxref dbxrf ".
                  "WHERE dbxrf.entry_id = ?");
  $sth->bind_param(1, $id, SQL_INTEGER);
  $sth->execute();

  my @array = @{$sth->fetchall_arrayref()};
  my @ids = map {$_->[0]} @array;
  my $dbxref_objs = $self->fetch_all_by_dbID_list(\@ids);
  return $dbxref_objs;
}

sub fetch_by_entry_id {
  my $self = shift;
  my $entry_id = shift;
  my $constraint = "dbxrf.entry_id = '$entry_id'";
  my ($dbxref_obj) = @{ $self->generic_fetch($constraint) };
  return $dbxref_obj;
}

sub fetch_by_database_id {
  my $self = shift;
  my $database_id = shift;
  my $constraint = "dbxrf.database_id = '$database_id'";
  my ($dbxref_obj) = @{ $self->generic_fetch($constraint) };
  return $dbxref_obj;
}

sub fetch_by_primary_id {
  my $self = shift;
  my $primary_id = shift;
  my $constraint = "dbxrf.primary_id = '$primary_id'";
  my ($dbxref_obj) = @{ $self->generic_fetch($constraint) };
  return $dbxref_obj;
}

sub fetch_by_secondary_id {
  my $self = shift;
  my $secondary_id = shift;
  my $constraint = "dbxrf.secondary_id = '$secondary_id'";
  my ($dbxref_obj) = @{ $self->generic_fetch($constraint) };
  return $dbxref_obj;
}

sub fetch_by_tertiary_id {
  my $self = shift;
  my $tertiary_id = shift;
  my $constraint = "dbxrf.tertiary_id = '$tertiary_id'";
  my ($dbxref_obj) = @{ $self->generic_fetch($constraint) };
  return $dbxref_obj;
}

sub fetch_by_quaternary_id {
  my $self = shift;
  my $quaternary_id = shift;
  my $constraint = "dbxrf.quaternary_id = '$quaternary_id'";
  my ($dbxref_obj) = @{ $self->generic_fetch($constraint) };
  return $dbxref_obj;
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
  my ( $dbxref_id, $entry_id, $database_id,
       $primary_id, $secondary_id,
       $tertiary_id, $quaternary_id );
  $sth->bind_columns( \$dbxref_id, \$entry_id, \$database_id,
                      \$primary_id, \$secondary_id,
                      \$tertiary_id, \$quaternary_id );

  while($sth->fetch()) {
    #print STDERR "$dbxref_id, $entry_id, $database_id, $primary_id, $secondary_id, $tertiary_id, $quaternary_id\n";
    push @out, Bio::EnsEMBL::ExternalData::Mole::DBXref->new(
              -adaptor        => $self,
              -dbID           => $dbxref_id,
              -entry_id       => $entry_id, 
              -database_id    => $database_id,
              -primary_id     => $primary_id,
              -secondary_id   => $secondary_id || undef,
              -tertiary_id    => $tertiary_id || undef,
              -quaternary_id  => $quaternary_id || undef
              );
  }
  return \@out;
}
1;

