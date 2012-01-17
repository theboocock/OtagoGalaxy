# $Id: FamilyMemberAdaptor.pm,v 1.11 2003-04-07 12:05:00 abel Exp $
# 
# Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyMemberAdaptor
# 
# Cared by Abel Ureta-Vidal <abel@ebi.ac.uk>
#
# Copyright EnsEMBL
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

FamilyAdaptor - DESCRIPTION of Object

  This object represents a database of protein families.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONTACT

=head1 APPENDIX

=cut

package Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyMemberAdaptor;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::ExternalData::Family::FamilyMember;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);

=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   : $memberadaptor->fetch_by_dbID($id);
 Function: fetches a FamilyMember given its internal database identifier
 Example : $memberadaptor->fetch_by_dbID(1)
 Returns : a Bio::EnsEMBL::ExternalData::Family::FamilyMember object if found, 
           undef otherwise
 Args    : an integer

=cut

sub fetch_by_dbID {
  my ($self, $dbID) = @_;

  $self->throw("dbID arg is required\n") unless ($dbID);

  my $constraint = "fm.family_member_id = $dbID";

  my $members = $self->_fetch_family_members($constraint);

  return undef if(!@$members);

  return $members->[0];
}

=head2 fetch_by_stable_id

 Title   : fetch_by_stable_id
 Usage   : $memberadaptor->fetch_by_stable_id($stable_id);
 Function: fetches a FamilyMember given its stable identifier 
           (external_member_id)
 Example : $db->fetch_by_stable_id('ENSG00000000009');
 Returns : a array ref of Bio::EnsEMBL::ExternalData::Family::FamilyMembers
           IMPORTANT: this method returns an array reference because the 
                      stable_id could not be unique
           i.e. the same member maybe part of more than one family
 Args    : an EnsEMBL Gene/Peptide stable id (e.g. ENSG00000000009) or 
           an Accession Number (e.g.O35622)

=cut

sub fetch_by_stable_id  {
    my ($self, $stable_id) = @_; 

    $self->throw("stable_id arg is required") unless ($stable_id);

    my $constraint = "fm.external_member_id = '$stable_id'";

    return $self->_fetch_family_members($constraint);
}           


sub fetch_by_family_id {
  my ($self, $family_id) = @_;

  $self->throw("family_id arg is required\n") unless ($family_id);

  my $constraint = "fm.family_id = $family_id";

  return $self->_fetch_family_members($constraint);
}

sub fetch_by_dbname {
  my ($self,$dbname) = @_;

  $self->throw("dbname arg is required\n") unless ($dbname);

  my $constraint = "ex.name = '$dbname'";

  return $self->_fetch_family_members($constraint);
}


sub fetch_by_dbname_taxon {
  my ($self,$dbname,$taxon_id) = @_;

  $self->throw("dbname and taxon_id args are required") 
    unless($dbname && $taxon_id);

  my $constraint = "ex.name = '$dbname' and fm.taxon_id = $taxon_id";

  return $self->_fetch_family_members($constraint);
}


sub fetch_by_family_dbname {
  my ($self,$family_id,$dbname) = @_;

  $self->throw("family_id and dbname args are required") 
    unless($family_id && $dbname);

  my $constraint = "fm.family_id = $family_id and ex.name = '$dbname'";
  
  return $self->_fetch_family_members($constraint);
}



sub fetch_by_family_dbname_taxon {
  my ($self,$family_id,$dbname,$taxon_id) = @_;

  $self->throw("family_id, dbname and taxon_id args are required") 
    unless ($family_id && $dbname && $taxon_id);
  
  my $constraint = "fm.family_id = $family_id 
                    AND ex.name = '$dbname'
                    AND fm.taxon_id = $taxon_id";

  return $self->_fetch_family_members($constraint);
}


sub _fetch_family_members {
  my ($self, $constraint) = @_;

  my $q = "SELECT fm.family_member_id, fm.family_id, fm.external_db_id, 
                  fm.external_member_id, fm.taxon_id, fm.alignment, ex.name
           FROM family_members fm, external_db ex
           WHERE ex.external_db_id = fm.external_db_id";

  if($constraint) {
    $q .= " AND $constraint";
  }

  my $sth = $self->prepare($q);
  $sth->execute();
 
  my ($family_member_id, $family_id, $external_db_id, $external_member_id,
      $taxon_id, $alignment_string, $external_db_name);

  $sth->bind_columns(\$family_member_id, \$family_id, \$external_db_id, 
		    \$external_member_id, \$taxon_id, \$alignment_string,
		    \$external_db_name);

  my @members;
  while($sth->fetch) {
    my $member = new Bio::EnsEMBL::ExternalData::Family::FamilyMember();
    $member->adaptor($self);
    $member->dbID($family_member_id);
    $member->family_id($family_id);
    $member->external_db_id($external_db_id);
    $member->database($external_db_name);
    $member->stable_id($external_member_id);
    $member->taxon_id($taxon_id);
    $member->alignment_string($alignment_string);
    push @members, $member;
  }

  return \@members;
}


sub get_external_db_id_by_dbname {
  my ($self, $dbname) = @_;

  $self->throw("Should give a defined databasename as argument\n") 
    unless (defined $dbname);

  my $q = "SELECT external_db_id FROM external_db WHERE name = ?";
  $q = $self->prepare($q);
  $q->execute($dbname);
  my $rowhash = $q->fetchrow_hashref;

  return $rowhash->{external_db_id};
}

sub get_dbname_by_external_db_id {
  my ($self, $external_db_id) = @_;

  $self->throw("Should give a defined external_db_id as argument\n") 
    unless (defined $external_db_id);

  my $q = "SELECT name FROM external_db WHERE external_db_id = ?";
  $q = $self->prepare($q);
  $q->execute($external_db_id);
  my $rowhash = $q->fetchrow_hashref;

  return $rowhash->{name};
}


=head2 store

  Arg [1]    : int family_id 
  Arg [2]    : Bio::EnsEMBL::ExternalData::Family::FamilyMember $member
  Example    : $member_id = $family_member_adaptor->store($family_id, $member);
  Description: Stores a family member object in the database.  On success the
               family member id is returned
  Returntype : int
  Exceptions : thrown if incorrect argument supplied
  Caller     : general

=cut

sub store {
  my ($self,$family_id,$member) = @_;
  
  unless($member->isa('Bio::EnsEMBL::ExternalData::Family::FamilyMember')) {
    $self->throw(
      "member arg must be a [Bio::EnsEMBL::ExternalData::Family::FamilyMember]"
    . "not a $member");
  }

  my $sth = 
    $self->prepare("INSERT INTO family_members (family_id, external_db_id, 
                                taxon_id, external_member_id,
                                alignment) 
                    VALUES (?,?,?,?,?)");

  $sth->execute($family_id, 
		$member->external_db_id, 
		$member->taxon_id,
		$member->primary_id,
		$member->alignment_string);

  $member->dbID( $sth->{'mysql_insertid'} );
  $member->adaptor($self);
  if (defined $member->taxon) {
    $self->db->get_TaxonAdaptor->store_if_needed($member->taxon);
  }
  return $member->dbID;
}



=head2 update

  Arg [1]    : Bio::EnsEMBL::ExternalData::Family::FamilyMember
  Example    : 
  Description: Updates the attributes of a family member that has already been
               stored in the database.  This is useful to update attributes
               such as a the alignment string which may have been calculated
               after the families were alreated created.  On success this 
               method returns the dbID of the updated member
  Returntype : int
  Exceptions : thrown if incorrect argument is provided
               thrown if the member to be updated does not have a dbID
  Caller     : general

=cut

sub update {
  my ($self, $member) = @_;

  unless($member->isa('Bio::EnsEMBL::ExternalData::Family::FamilyMember')) {
    $self->throw(
      "member arg must be a [Bio::EnsEMBL::ExternalData::Family::FamilyMember".
      "not a [$member]");
  }

  unless($member->dbID) {
    $self->throw("Family member does not have a dbID and cannot be updated");
  }

  my $sth = 
    $self->prepare("UPDATE family_members 
                    SET    family_id = ?, 
                           external_db_id = ?, 
                           external_member_id = ?, 
                           taxon_id = ?, 
                           alignment = ?
                    WHERE  family_member_id = ?");

  $sth->execute($member->family_id, $member->external_db_id, 
                $member->primary_id, $member->taxon_id, 
                $member->alignment_string, $member->dbID);

  return $member->dbID;
}


1;






