package Bio::EnsEMBL::ExternalData::Mole::DBSQL::KeywordAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Keyword;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['keyword' , 'kw']);
}

sub _columns {
  my $self = shift;
  return ( 'kw.keyword_id', 'kw.entry_id',
           'kw.keyword', 'kw.qualifier');
}

sub fetch_by_dbID {
  my $self = shift;
  my $id = shift;
  my $constraint = "kw.keyword_id = '$id'";
  my ($keyword_obj) = @{ $self->generic_fetch($constraint) };
  return $keyword_obj;
}

sub fetch_by_Entry {
  my $self = shift;
  my $entry = shift;
  my $sth = $self->prepare(
            "SELECT kw.keyword_id ".
            "FROM keyword kw.".
            "WHERE kw.entry_id = ?");
  $sth->bind_param(1, $entry->dbID, SQL_INTEGER);
  $sth->execute();
  my $kw_id = $sth->fetchrow();
  $sth->finish();

  my $keyword_object = $self->fetch_by_dbID($kw_id);
  return $keyword_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "kw.entry_id = '$entry_id'";
  my ($keyword_obj) = @{ $self->generic_fetch($constraint) };
  return $keyword_obj;
}

sub fetch_by_keyword {
  my $self = shift;
  my $keyword = shift;

  #get all entry_ids with this keyword
  $sth = $self->prepare(
         "SELECT entry_id ".
         "FROM keyword ".
         "WHERE keyword = '$keyword' ");
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
  my ( $keyword_id, $entry_id, $keyword );
  $sth->bind_columns( \$keyword_id, \$entry_id, \$keyword );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::Keyword->new(
              -dbID           => $keyword_id,
              -entry_id       => $entry_id,
              -adaptor        => $self,
              -keyword        => $keyword,
              );
  }
  return \@out;
}


1;

