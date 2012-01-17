# $Id: Family.pm,v 1.28 2003-07-18 13:56:13 mcvicker Exp $
#
# BioPerl module for Family
#
# Initially cared for by Philip Lijnzaad <lijnzaad@ebi.ac.uk>
# Now cared by Abel Ureta-Vidal <abel@ebi.ac.uk> and Elia Stupka <elia@fugu-sg.org>
#
# Copyright Philip Lijnzaad
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Family - DESCRIPTION of Object

=head1 SYNOPSIS

  use Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor;
  use Bio::EnsEMBL::ExternalData::Family::FamilyAdaptor;
  use Bio::EnsEMBL::ExternalData::Family::Family;

  $famdb = Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor->new(
					     -user   => 'myusername',
                                             -dbname => 'myfamily_db',
                                             -host   => 'myhost',
                                              );

  my $fam_adtor = $famdb->get_FamilyAdaptor;

  my $fam = $fam_adtor->fetch_by_stable_id('ENSP00000012304');

  print $fam->description, join('; ',$fam->keywords,$fam->release, 
    $fam->annotation_confidence_score, $fam->size);


=head1 DESCRIPTION

This object describes protein families obtained from clustering
SWISSPROT/TREMBL using Tribe MCL algorithm. The clustering
neatly follows the SWISSPROT/TREMBL DE-lines, which are taken as the
description of the whole family.

SWSISSPROT keywords aren't there yet either. 

The family members are currently represented by Bio::EnsEMBL::ExternalData::Family::Family
objects



=head1 CONTACT

 Philip Lijnzaad <Lijnzaad@ebi.ac.uk> [original perl modules]
 Anton Enright <enright@ebi.ac.uk> [TRIBE algorithm]
 Elia Stupka <elia@fugu-sg.org> [refactoring]
 Able Ureta-Vidal <abel@ebi.ac.uk> [multispecies migration]

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

# ';  # (pacify emacs).  

# Let the code begin...;

package Bio::EnsEMBL::ExternalData::Family::Family;
use vars qw(@ISA);
use strict;

# Object preamble - inheriets from Bio::EnsEMBL::Root
use Bio::EnsEMBL::Root;
use IO::File;
use Bio::SimpleAlign;
use Bio::LocatableSeq;

@ISA = qw(Bio::EnsEMBL::Root);

=head2 new

 Title   : new
 Usage   : not intended for general use.
 Function:
 Example :
 Returns : a family (but without members; caller has to fill using
           add_member)
 Args    :
         
=cut

sub new {
  my($class,@args) = @_;
  
  my $self = $class->SUPER::new(@args);
  
  if (scalar @args) {
     #do this explicitly.
     my ($dbid, $stable_id,$descr,$release, $score, $memb,$adap) = $self->_rearrange([qw(DBID STABLE_ID DESCRIPTION RELEASE SCORE MEMBERS ADAPTOR)], @args);
      
      $dbid && $self->dbID($dbid);
      $stable_id || $self->throw("Must have a stable_id");
      $self->stable_id($stable_id);

      $descr || $self->throw("family must have a description");
      $self->description($descr);

      $release && $self->release($release);
      $score && $self->annotation_confidence_score($score);
      $self->{_members} = []; 
      push (@{$self->{_members}},@{$memb});
      $adap && $self->adaptor($adap);
  }
  
  return $self;
}   

=head2 adaptor

 Title   : adaptor
 Usage   : $adaptor = $fam->adaptor
 Function: find this objects\'s adaptor object (set by FamilyAdaptor)
 Example :
 Returns : 
 Args    : 

=cut

sub adaptor {
  my ($self,$value)= @_;
  
  if (defined $value) {
    $self->{'adaptor'} = $value;
  }

  return $self->{'adaptor'};
}


=head2 stable_id

 Title   : stable_id
 Usage   : 
 Function: get/set the display stable_id of the Family
 Example :
 Returns : 
 Args    : 

=cut

sub stable_id {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'stable_id'} = $value;
    }
    return $self->{'stable_id'};
}

=head2 dbID

 Title   : dbID
 Usage   : 
 Function: get/set the dbID of the Family
 Example :
 Returns : 
 Args    : 

=cut

sub dbID {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'dbID'} = $value;
    }
    return $self->{'dbID'};
}

=head2 description

 Title   : description
 Usage   : 
 Function: get/set the description of the Family. 
 Example :
 Returns : A string (currently all upper case, and no longer than 255 chars).
 Args    : 

=cut

sub description {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'desc'} = $value;
    }
    return $self->{'desc'};
}

=head2 release

 Title   : release
 Usage   : 
 Function: get/set the release number of the family database;
 Example :
 Returns : 
 Args    : 

=cut

sub release {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'release'} = $value;
    }
    return $self->{'release'};
}

=head2 annotation_confidence_score

 Title   : annotation_confidence_score
 Usage   : 

 Function: get/set the annotation_confidence_score of the Family. This a
           measure of how good the cluster is (what is the scale??)
 Example :
 Returns : 
 Args    : 

=cut

sub annotation_confidence_score {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'annotation_confidence_score'} = $value;
    }
    return $self->{'annotation_confidence_score'};
}

=head2 size

 Title   : size
 Usage   : $fam->size
 Function: returns the number of peptide members of the family
 Returns : an int
 Args    : none

=cut

sub size {
  my ($self) = @_; 
  
  # we do not want to have a total number of gene+peptide members (that is non sense)
  # That is why we substracte from the total those corresponding to genes
  # Need to be fixed as ENSEMBLGENE is here hard coded
  # Probably by just adding a colunm type in external_db, which would be gene, peptide, or
  # even transcript. Then recode size as size_by_type or something like that.
  # size_by_type('peptide'),...

  return scalar @{$self->get_all_members} - $self->size_by_dbname('ENSEMBLGENE');
}

=head2 size_by_dbname

 Title   : size_by_dbname
 Usage   : $fam->size_by_dbname('ENSEMBLGENE')
 Function: returns the number of members of the family belonging to a particular databasename
 Returns : an int
 Args    : a databasename


=cut

sub size_by_dbname {
  my ($self, $dbname) = @_; 
  
  $self->throw("Should give a defined databasename as argument\n") unless (defined $dbname);
  
  return scalar @{$self->get_members_by_dbname($dbname)};
}

=head2 size_by_dbname_taxon

 Title   : size_by_dbname_taxon
 Usage   : $fam->size_by_dbname_taxon('ENSEMBLGENE',9606)
 Function: returns the number of members of the family belonging to a particular databasename and a taxon
 Returns : an int
 Args    : a databasename and a taxon_id

=cut

sub size_by_dbname_taxon {
  my ($self, $dbname, $taxon_id) = @_; 
  
  $self->throw("Should give defined databasename and taxon_id as arguments\n") unless (defined $dbname && defined $taxon_id);

  return scalar @{$self->get_members_by_dbname_taxon($dbname,$taxon_id)};
}




=head2 get_SimpleAlign

  Arg [1]    : get_SimpleAlign
  Example    : none
  Description: Returns a Bio::SimpleAlign feature constructed from the
               multiple alignment of this Families members.
               The SimpleAlign can then be printed out in many different
               formats using the Bio::ALignIO module
  Returntype : Bio::SimpleAlign
  Exceptions : none
  Caller     : general

=cut

sub get_SimpleAlign {
  my $self = shift;
  
  my $sa = Bio::SimpleAlign->new();

  #Hack to try to work with both bioperl 0.7 and 1.2:
  #Check to see if the method is called 'addSeq' or 'add_seq'
  my $bio07 = 0;
  if(!$sa->can('add_seq')) {
    $bio07 = 1;
  }
  
  foreach my $member (@{$self->get_all_members}) {
    my $seqstr = $member->alignment_string;
    next if(!$seqstr);
    my $seq = Bio::LocatableSeq->new(-SEQ    => $seqstr,
                                     -START  => 1,
                                     -END    => length($seqstr),
                                     -ID     => $member->stable_id,
                                     -STRAND => 0);
    
    if($bio07) {
      $sa->addSeq($seq);
    } else {
      $sa->add_seq($seq);
    }
  }

  return $sa;
}

=head2 get_all_members

 Title   : get_all_members
 Usage   : foreach $member ($fam->get_all_members) {...
 Function: fetch all the members of the family
 Example :
 Returns : an array reference of 
           Bio::EnsEMBL::ExternalData::Family::FamilyMember objects (which may
           be empty)
 Args    : none

=cut

sub get_all_members {
  my ($self) = @_;
  
  unless (defined $self->{'_members'}) {
    my $family_id = $self->dbID;
    my $FamilyMemberAdaptor = $self->adaptor->db->get_FamilyMemberAdaptor();
    my $members = $FamilyMemberAdaptor->fetch_by_family_id($family_id);
    $self->{_members} = [];
    $self->{_members_by_dbname} = {};
    $self->{_members_by_dbname_taxon} = {};
    foreach my $member (@{$members}) {
      $self->add_member($member);
    }
  }
#  return @{$self->{'_members'}};
  return $self->{'_members'};
}

=head2 get_members_by_dbname

 Title   : get_members_by_dbname
 Usage   : $fam->get_members_by_dbname('SPTR')
 Function: fetch all the members that belong to a particular database
 Returns : an array reference of Bio::EnsEMBL::ExternalData::Family::FamilyMember objects (which may be empty)
 Args    : a databasename

=cut

sub get_members_by_dbname {
  my ($self, $dbname) = @_;

  $self->throw("Should give defined databasename as arguments\n") unless (defined $dbname);

  unless (defined $self->{_members_by_dbname}->{$dbname}) {
    my $family_id = $self->dbID;
    my $FamilyMemberAdaptor = $self->adaptor->db->get_FamilyMemberAdaptor();
    my $members = $FamilyMemberAdaptor->fetch_by_family_dbname($family_id,$dbname);

    $self->{_members_by_dbname}->{$dbname} = [];
    push @{$self->{_members_by_dbname}->{$dbname}}, @{$members};
  }
#  return @{$self->{_members_by_dbname}->{$dbname}};
  return $self->{_members_by_dbname}->{$dbname};

}

=head2 get_members_by_dbname_taxon

 Title   : get_members_by_dbname_taxon
 Usage   : $obj->get_members_by_dbname_taxon('ENSEMBLGENE',9606)
 Function: fetch all the members that belong to a particular database and taxon_id
 Returns : an array reference of Bio::EnsEMBL::ExternalData::Family::FamilyMember objects (which may be empty)
 Args    : a databasename and taxon_id

=cut

sub get_members_by_dbname_taxon {
  my ($self, $dbname, $taxon_id) = @_;

  $self->throw("Should give defined databasename and taxon_id as arguments\n") unless (defined $dbname && defined $taxon_id);

  unless (defined $self->{_members_by_dbname_taxon}->{$dbname."_".$taxon_id}) {
    my $family_id = $self->dbID;
    my $FamilyMemberAdaptor = $self->adaptor->db->get_FamilyMemberAdaptor();
    my $members = $FamilyMemberAdaptor->fetch_by_family_dbname_taxon($family_id,$dbname,$taxon_id);

    $self->{_members_by_dbname_taxon}->{$dbname."_".$taxon_id} = [];
    push @{$self->{_members_by_dbname_taxon}->{$dbname."_".$taxon_id}}, @{$members};
  }
#  return @{$self->{_members_by_dbname_taxon}->{$dbname."_".$taxon_id}};
  return $self->{_members_by_dbname_taxon}->{$dbname."_".$taxon_id};
}

=head2 get_Taxon_by_dbname

 Arg [1]    : string $dbname
              Either "ENSEMBLGENE", "ENSEMBLPEP" or "SPTR" 
 Example    : $family->get_Taxon_by_dbname('ENSEMBLGENE')
 Description: get all the taxons that belong to a particular database in the 
              corresponding family
 Returntype : an array reference of Bio::EnsEMBL::ExternalData::Family::Taxon objects
              (which may be empty)
 Exceptions : when missing argument
 Caller     : general

=cut

sub get_Taxon_by_dbname {
  my ($self, $dbname) = @_;
  
  $self->throw("Should give defined databasename as argument\n") unless (defined $dbname);

  my $family_id = $self->dbID;
  my $FamilyAdaptor = $self->adaptor;

  return $FamilyAdaptor->fetch_Taxon_by_dbname_dbID($dbname,$family_id);
}

=head2 add_member

 Title   : add_member
 Usage   : 
 Function: adds member to family. 
 Example : $fam->add_member($family_member);
 Returns : undef
 Args    : a Bio::EnsEMBL::ExternalData::Family::FamilyMember object

=cut

sub add_member { 
    my ($self, $member) = @_; 
    
    $member->isa('Bio::EnsEMBL::ExternalData::Family::FamilyMember') ||
      $self->throw("You have to add a Bio::EnsEMBL::ExternalData::Family::FamilyMember object, not a $member");
   
    push @{$self->{_members}}, $member;
    push @{$self->{_members_by_dbname}{$member->database}}, $member;
    push @{$self->{_members_by_dbname_taxon}{$member->database."_".$member->taxon_id}}, $member;
}




=head2 read_clustalw

  Arg [1]    : string $file 
               The name of the file containing the clustalw output  
  Example    : $family->read_clustalw('/tmp/clustalw.aln');
  Description: Parses the output from clustalw and sets the alignment strings
               of each of the memebers of this family
  Returntype : none
  Exceptions : thrown if file cannot be parsed
               warning if alignment file contains identifiers for sequences
               which are not members of this family
  Caller     : general

=cut

sub read_clustalw {
  my $self = shift;
  my $file = shift;

  my %align_hash;
  my $FH = IO::File->new();
  $FH->open($file) || $self->throw("Could not open alignment file [$file]");

  <$FH>; #skip header
  while(<$FH>) {
    next if($_ =~ /^\s+/);  #skip lines that start with space
    
    my ($id, $align) = split;
    $align_hash{$id} ||= '';
    $align_hash{$id} .= $align;
  }

  $FH->close;

  #place all family members in a hash on their names
  my %member_hash;
  foreach my $member (@{$self->get_all_members}) {
    $member_hash{$member->stable_id} = $member;
  }

  #assign alignment strings to each of the members
  foreach my $id (keys %align_hash) {
    my $member = $member_hash{$id};
    if($member) {
      $member->alignment_string($align_hash{$id});
    } else {
      $self->warn("No member for alignment portion: [$id]");
    }
  }
}





###########################################
#
# Deprecated methods. Will be deleted soon.

sub each_member {
  my ($self) = @_;

  $self->warn("Family->each_member is a deprecated method!
Calling Family->get_all_members instead!");
  
  return $self->get_all_members;
}

sub each_member_of_db {
  my ($self, $dbname) = @_;

  $self->warn("Family->each_member_of_db is a deprecated method!
Calling Family->get_members_by_dbname instead!");
  
  return $self->get_members_by_dbname($dbname);
}

sub each_member_of_db_taxon {
  my ($self, $dbname, $taxon_id) = @_;

  $self->warn("Family->each_member_of_db_taxon is a deprecated method!
Calling Family->get_members_by_dbname_taxon instead!");
  
  return $self->get_members_by_dbname_taxon($dbname,$taxon_id);
}

1;
