package Bio::EnsEMBL::ExternalData::Mole::DBSQL::EntryAdaptor; 

use strict;
use Bio::EnsEMBL::ExternalData::Mole::Entry;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['entry' , 'e']);
}

sub _columns {
  my $self = shift;
  return ( 'e.entry_id',
           'e.accession_version',
           'e.name', 
           'e.topology',
           'e.molecule_type',
           'e.data_class',
           'e.tax_division',
           'e.sequence_length',
           'e.last_updated',
           'e.first_submitted');
}

sub fetch_by_dbID {
  my $self = shift;
  my $entryid = shift;
  my $constraint = "e.entry_id = '$entryid'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub full_fetch_by_dbID {
  my ($self, $objectid) = @_;
  my $constraint = "e.entry_id = '$objectid'";
  my ($entry_object) = @{$self->generic_fetch($constraint)};

  my $description_obj = $self->db()->get_DescriptionAdaptor->fetch_by_entry_id($entry_object->dbID);
  $entry_object->description_obj($description_obj);

  my $sequence_obj = $self->db()->get_SequenceAdaptor->fetch_by_entry_id($entry_object->dbID);
  $entry_object->sequence_obj($sequence_obj);
  
  my $accession_obj = $self->db()->get_AccessionAdaptor->fetch_by_entry_id($entry_object->dbID);
  $entry_object->accession_obj($accession_obj);

  my $taxonomy_obj = $self->db()->get_TaxonomyAdaptor->fetch_by_entry_id($entry_object->dbID);
  $entry_object->taxonomy_obj($taxonomy_obj);

  my $dbxrefs = $self->db()->get_DBXrefAdaptor->fetch_all_by_entry_id($entry_object->dbID);
  $entry_object->{'dbxref_objs'} = $dbxrefs;

  my $comments = $self->db()->get_CommentAdaptor->fetch_all_by_entry_id($entry_object->dbID);
  $entry_object->{'comment_objs'} = $comments;

  return $entry_object;
}

sub fetch_all_by_ncbi_taxID {
  my $self = shift;
  my $ncbi_taxonomy_id = shift;

  my $sth = $self->prepare(
            "SELECT t.entry_id ".
            "FROM taxonomy t ".
            "WHERE t.ncbi_tax_id = ?");
  $sth->bind_param(1, $ncbi_taxonomy_id, SQL_INTEGER);
  $sth->execute();

  my @entries; 
  while ( my $id = $sth->fetchrow()) {
    push @entries, $self->db()->get_EntryAdaptor->full_fetch_by_dbID($id);
  }

  return \@entries;
}

sub fetch_all_by_description_tag {
  my $self = shift;
  my $description_tag = shift;

  my $sth = $self->prepare(
            "SELECT d.entry_id ".
            "FROM description d ".
            "WHERE d.description like ?");
  $sth->bind_param(1, $description_tag, SQL_VARCHAR);
  $sth->execute();

  my @entries;
  while ( my $id = $sth->fetchrow()) {
    push @entries, $self->db()->get_EntryAdaptor->full_fetch_by_dbID($id);
  }

  return \@entries;
}

sub fetch_by_primary_id {
  my $self = shift;
  my $primary_id = shift;
  my $sth = $self->prepare(
            "SELECT e.entry_id ".
            "FROM entry e, dbxref dbxrf ".
            "WHERE e.entry_id=dbxrf.entry_id ".
            "AND dbxrf.primary_id=? ".
            "AND dbxrf.secondary_id=\'source\'");
  $sth->bind_param(1, $primary_id, SQL_VARCHAR);
  $sth->execute;
  my ($entry_id) = $sth->fetchrow();
  $sth->finish();

  return undef if (!defined $entry_id);
  my $entry = $self->fetch_by_dbID($entry_id);
  return $entry;
 
}

sub fetch_by_accession {
  my $self = shift;
  my $acc = shift;
  my $sth = $self->prepare(
            "SELECT a.entry_id ".
            "FROM accession a ".
            "WHERE a.accession = ?");
  $sth->bind_param(1, $acc, SQL_VARCHAR);
  $sth->execute;

  my ($entry_id) = $sth->fetchrow();
  $sth->finish();

  return undef if (!defined $entry_id);
  my $entry = $self->fetch_by_dbID($entry_id);
  return $entry;
}

sub fetch_by_accession_version {
  my $self = shift;
  my $acc = shift;
  my $constraint = "e.accession_version = '$acc'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_accession_noversion {
  my $self = shift;
  my $acc = shift;
  my $constraint = "e.name = '$acc'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "e.name = '$name'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_topology {
  my $self = shift;
  my $topology = shift;
  my $constraint = "e.topology = '$topology'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_molecule_type {
  my $self = shift;
  my $molecule_type = shift;
  my $constraint = "e.molecule_type = '$molecule_type'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_data_class {
  my $self = shift;
  my $data_class = shift;
  my $constraint = "e.data_class = '$data_class'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_tax_division {
  my $self = shift;
  my $tax_division = shift;
  my $constraint = "e.tax_division = '$tax_division'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_by_sequence_length {
  my $self = shift;
  my $sequence_length = shift;
  my $constraint = "e.sequence_length = '$sequence_length'";
  my ($entry_obj) = @{ $self->generic_fetch($constraint) };
  return $entry_obj;
}

sub fetch_all_for_est_update {
  my ($self, $taxdivision) = @_;

  my $sth = $self->prepare(
                           "SELECT e.entry_id ".
                           "FROM entry e ".
                           "WHERE e.tax_division = ? ".
                           "AND e.data_class = 'EST'"); 

  $sth->bind_param(1, $taxdivision, SQL_CHAR);
  $sth->execute();

  my @entries;
  while ( my $id = $sth->fetchrow()) {
    push @entries, $self->db()->get_EntryAdaptor->fetch_entry_seq_and_comment_by_dbID($id);
  }

  return \@entries;
}

sub fetch_entry_seq_and_comment_by_dbID {
  my ($self, $objectid) = @_;
  my $constraint = "e.entry_id = '$objectid'";
  my ($entry_object) = @{$self->generic_fetch($constraint)};

  my $sequence_obj = $self->db()->get_SequenceAdaptor->fetch_by_entry_id($entry_object->dbID);
  $entry_object->sequence_obj($sequence_obj);

  my $comments = $self->db()->get_CommentAdaptor->fetch_all_by_entry_id($entry_object->dbID);
  $entry_object->comment_objs($comments);

  return $entry_object;
}

sub fetch_all_by_dbID_list {
  my ($self,$id_list_ref) = @_;

  if(!defined($id_list_ref) || ref($id_list_ref) ne 'ARRAY') {
    throw("entry id list reference argument is required");
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
  my ( $entry_id, $accession_version, $name,
       $topology, $molecule_type, $data_class,
       $tax_division, $sequence_length,
       $last_updated, $first_submitted );
  $sth->bind_columns( \$entry_id, \$accession_version, \$name, 
                      \$topology, \$molecule_type, \$data_class,
                      \$tax_division, \$sequence_length,
                      \$last_updated, \$first_submitted);

  while($sth->fetch()) {
    my $acc_obj = $self->db->get_AccessionAdaptor->fetch_by_entry_id($entry_id);
    my $dbxref_objs = $self->db->get_DBXrefAdaptor->fetch_all_by_entry_id($entry_id);
    my $desc_obj = $self->db->get_DescriptionAdaptor->fetch_by_entry_id($entry_id);
    my $seq_obj = $self->db->get_SequenceAdaptor->fetch_by_entry_id($entry_id);
    my $taxonomy_obj = $self->db->get_TaxonomyAdaptor->fetch_by_entry_id($entry_id);
    push @out, Bio::EnsEMBL::ExternalData::Mole::Entry->new(
              -dbID               => $entry_id,
              -accession_version  => $accession_version,
              -name               => $name,
              -topology           => $topology,
              -molecule_type      => $molecule_type,
              -data_class         => $data_class,
              -tax_division       => $tax_division,
              -sequence_length    => $sequence_length,
              -last_updated       => $last_updated,
              -first_submitted    => $first_submitted,
              -accession_obj      => $acc_obj,
              -dbxref_objs        => $dbxref_objs, 
              -description_obj    => $desc_obj,
              -sequence_obj       => $seq_obj,
              -taxonomy_obj       => $taxonomy_obj,
              );
  }
  return \@out;
}


1;

