package Bio::EnsEMBL::ExternalData::Mole::DBSQL::BlackListAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::BlackList;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['blacklist' , 'b']);
}

sub _columns {
  my $self = shift;
  return ( 'b.blacklist_id', 'b.entry_id',
           'b.rating', 'b.reason',
           'b.submitter', 'b.submission_date');
}

sub fetch_by_dbID {
  my $self = shift;
  my $id = shift;
  my $constraint = "b.blacklist_id = '$id'";
  my ($blacklist_obj) = @{ $self->generic_fetch($constraint) };
  return $blacklist_obj;
}

sub fetch_by_Entry {
  my $self = shift;
  my $entry = shift;
  my $sth = $self->prepare(
            "SELECT b.blacklist_id ".
            "FROM blacklist b ".
            "WHERE b.entry_id = ?");
  $sth->bind_param(1, $entry->dbID, SQL_INTEGER);
  $sth->execute();
  my $black_id = $sth->fetchrow();
  $sth->finish();

  my $blacklist_object = $self->fetch_by_dbID($black_id);
  return $blacklist_object;
}

sub fetch_by_entry_id {
  my ($self, $entry_id) = @_;
  my $constraint = "b.entry_id = '$entry_id'";
  my ($blacklist_obj) = @{ $self->generic_fetch($constraint) };
  return $blacklist_obj;
}

sub fetch_by_rating {
  my $self = shift;
  my $rated = shift;

  #get all entry_ids with this rating
  $sth = $self->prepare(
         "SELECT entry_id ".
         "FROM blacklist ".
         "WHERE rating = '$rated' ");
  $sth->execute();
  my @array = @{$sth->fetchall_arrayref()};
  my @entry_ids = map {$_->[0]} @array;
  my $entries = $self->fetch_all_by_dbID_list(\@entry_ids);

  return $entries;
}

sub fetch_by_reason {
  my $self = shift;
  my $reason = shift;

  #get all entry_ids with this reason
  $sth = $self->prepare(
         "SELECT entry_id ".
         "FROM blacklist ".
         "WHERE reason = '$reason' ");
  $sth->execute();
  my @array = @{$sth->fetchall_arrayref()};
  my @entry_ids = map {$_->[0]} @array;
  my $entries = $self->fetch_all_by_dbID_list(\@entry_ids);

  return $entries;
}
                                
sub fetch_by_submitter {
  my $self = shift;
  my $submitter = shift;

  #get all entry_ids with this submitter
  $sth = $self->prepare(
         "SELECT entry_id ".
         "FROM blacklist ".
         "WHERE submitter = '$submitter' ");
  $sth->execute();
  my @array = @{$sth->fetchall_arrayref()};
  my @entry_ids = map {$_->[0]} @array;
  my $entries = $self->fetch_all_by_dbID_list(\@entry_ids);

  return $entries;
}

sub fetch_by_submission_date {
  my $self = shift;
  my $submission_date = shift;

  #get all entry_ids with this submission_date
  $sth = $self->prepare(
         "SELECT entry_id ".
         "FROM blacklist ".
         "WHERE date(submission_date) = '$submission_date' ");
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
  my ( $blacklist_id, $entry_id, $rating, $reason,
       $submitter, $submission_date );
  $sth->bind_columns( \$blacklist_id, \$entry_id, \$rating, \$reason,
                      \$submitter, \$submission_date );

  while($sth->fetch()) {
    push @out, Bio::EnsEMBL::ExternalData::Mole::BlackList->new(
              -dbID            => $blacklist_id,
              -entry_id        => $entry_id,
              -adaptor         => $self,
              -rating          => $rating,
              -reason          => $reason,
              -submitter       => $submitter,
              -submission_date => $submission_date,
              );
  }
  return \@out;
}


1;

