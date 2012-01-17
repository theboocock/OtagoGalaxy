package Bio::EnsEMBL::ExternalData::Mole::DBSQL::CommentAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Comment;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['comment' , 'cmnt']);
}

sub _columns {
  my $self = shift;
  return ( 'cmnt.comment_id', 'cmnt.entry_id',
           'cmnt.comment_key','cmnt.comment_value');
}

sub fetch_by_dbID {
  my ($self, $id) = @_;
  my $constraint = "cmnt.comment_id = '$id'";
  my ($comment_obj) = @{ $self->generic_fetch($constraint) };
  return $comment_obj;
}

sub fetch_all_by_Entry {
  my $self = shift;
  my $entry = shift;
  my $sth = $self->prepare(
            "SELECT cmnt.comment_id ".
            "FROM comment cmnt ".
            "WHERE cmnt.entry_id = ?");
  $sth->bind_param(1, $entry->dbID, SQL_INTEGER);
  $sth->execute();
  my @commentids;
  while (my $id = $sth->fetchrow) {
    push @commentids, $id;
  }
  $sth->finish();

  #my @obj_ids = map {$_->[0]} @commentids;
  my @obj_ids = @commentids;
  my @comments;
  foreach my $id (@obj_ids) {
    my $comment_object = $self->fetch_by_dbID($id);
    push @comments, $comment_object;
  }
  return \@comments;
}

sub fetch_all_by_entry_id {
  my ($self, $id) = @_;

  my $sth = $self->prepare(
                  "SELECT cmnt.comment_id ".
                  "FROM comment cmnt ".
                  "WHERE cmnt.entry_id = ?");
  $sth->bind_param(1, $id, SQL_INTEGER);
  $sth->execute();

  my @array = @{$sth->fetchall_arrayref()};
  my @ids = map {$_->[0]} @array;
  my $comment_objs = $self->fetch_all_by_dbID_list(\@ids);
  return $comment_objs;
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
  my ( $comment_id, $entry_id,
       $comment_key, $comment_value);
  $sth->bind_columns( \$comment_id, \$entry_id, 
                      \$comment_key, \$comment_value);

  while($sth->fetch()) {
    #print STDERR "$comment_id, $entry_id, $comment_key, $comment_value\n";
    push @out, Bio::EnsEMBL::ExternalData::Mole::Comment->new(
              -adaptor        => $self,
              -dbID           => $comment_id,
              -entry_id       => $entry_id, 
              -comment_key     => $comment_key || undef,
              -comment_value   => $comment_value || undef,
              );
  }
  return \@out;
}
1;

