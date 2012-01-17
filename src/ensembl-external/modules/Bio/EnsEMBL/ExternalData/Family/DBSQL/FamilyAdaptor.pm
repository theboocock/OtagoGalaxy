# $Id: FamilyAdaptor.pm,v 1.15 2003-05-09 14:35:59 abel Exp $
# 
# BioPerl module for Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyAdaptor
# 
# Initially cared for by Philip Lijnzaad <lijnzaad@ebi.ac.uk>
# Now cared by Elia Stupka <elia@fugu-sg.org> and Abel Ureta-Vidal <abel@ebi.ac.uk>
#
# Copyright EnsEMBL
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

FamilyAdaptor - DESCRIPTION of Object

  This object represents a family coming from a database of protein families.

=head1 SYNOPSIS

  use Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor;

  my $famdb = new Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor(-user   => 'myusername',
								       -dbname => 'myfamily_db',
								       -host   => 'myhost');

  my $fam_adtor = $famdb->get_FamilyAdaptor;

  my $fam = $fam_adtor->fetch_by_stable_id('ENSF000013034');
  my @fam = @{$fam_adtor->fetch_by_dbname_id('SPTR', 'P000123')};
  @fam = @{$fam_adtor->fetch_by_description_with_wildcards('interleukin',1)};
  @fam = @{$fam_adtor->fetch_all()};

  ### You can add the FamilyAdaptor as an 'external adaptor' to the 'main'
  ### Ensembl database object, then use it as:

  $ensdb = new Bio::EnsEMBL::DBSQL::DBAdaptor->(-user....);

  $ensdb->add_db_adaptor('MyfamilyAdaptor', $fam_adtor);

  # then later on, elsewhere: 
  $fam_adtor = $ensdb->get_db_adaptor('MyfamilyAdaptor');

  # also available:
  $ensdb->get_all_db_adaptors;
  $ensdb->remove_db_adaptor('MyfamilyAdaptor');

=head1 DESCRIPTION

This module is an entry point into a database of protein families,
clustering SWISSPROT/TREMBL and ensembl protein sets using the TRIBE MCL algorithm.
The clustering neatly follows the SWISSPROT DE-lines, which are 
taken as the description of the whole family.

The objects can be read from and write to a family database.

For more info, see ensembl-doc/family.txt

=head1 CONTACT

 Philip Lijnzaad <Lijnzaad@ebi.ac.uk> [original perl modules]
 Anton Enright <enright@ebi.ac.uk> [TRIBE algorithm]
 Elia Stupka <elia@fugu-sg.org> [refactoring]
 Able Ureta-Vidal <abel@ebi.ac.uk> [multispecies migration]

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyAdaptor;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::ExternalData::Family::Family;
use Bio::EnsEMBL::ExternalData::Family::FamilyMember;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Family::FamilyConf;
use Bio::EnsEMBL::ExternalData::Family::Taxon;

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);

=head2 list_familyIds

  Arg [1]    : none
  Example    : @family_ids = $family_adaptor->list_familyIds();
  Description: Gets an array of internal ids for all families in the current db
  Returntype : list of ints
  Exceptions : none
  Caller     : ?

=cut

sub list_familyIds {
   my ($self) = @_;

   my @out;
   my $sth = $self->prepare("SELECT family_id FROM family");
   $sth->execute;

   while (my ($id) = $sth->fetchrow) {
       push(@out, $id);
   }

   $sth->finish;

   return \@out;
}

=head2 fetch_by_dbID

 Arg [1]    : int $dbID
 Example    : $fam = $FamilyAdaptor->fetch_by_dbID(1);
 Description: fetches a Family given its database identifier
 Returntype : an Bio::EnsEMBL::ExternalData::Family::Family object
 Exceptions : when missing arguments
 Caller     : general

=cut

sub fetch_by_dbID {
  my ($self,$fid) = @_;
  
  $self->throw("Should give a defined family_id as argument\n") unless (defined $fid);

  my $q = "SELECT family_id,stable_id,description,release,annotation_confidence_score
           FROM family
           WHERE family_id = $fid";
  
  return $self->_get_family($q);

}

=head2 fetch_by_stable_id

 Arg [1]    : string $family_stable_id
 Example    : $fam = $FamilyAdaptor->fetch_by_stable_id('ENSF00000000009');
 Description: fetches a Family given its stable identifier
 Returntype : an Bio::EnsEMBL::ExternalData::Family::Family object
 Exceptions : when missing arguments
 Caller     : general

=cut

sub fetch_by_stable_id  {
    my ($self, $stable_id) = @_; 

    $self->throw("Should give a defined family_stable_id as argument\n") unless (defined $stable_id);

    my $q = "SELECT family_id FROM family WHERE stable_id = '$stable_id'";
    $q = $self->prepare($q);
    $q->execute;
    my ($id) = $q->fetchrow_array;
    $id || $self->throw("Could not find family for stable id $stable_id");
    return $self->fetch_by_dbID($id);
}           

=head2 fetch_by_dbname_id

 Arg [1]    : string $dbname
 Arg [2]    : string $member_stable_id
 Example    : $fams = $FamilyAdaptor->fetch_of_dbname_id('SPTR', 'P01235');
 Description: find the family to which the given database and  member_stable_id belong
 Returntype : an array reference of Bio::EnsEMBL::ExternalData::Family::Family objects
              (could be empty or contain more than one Family in the case of ENSEMBLGENE only)
 Exceptions : when missing arguments
 Caller     : general

=cut

sub fetch_by_dbname_id { 
    my ($self, $dbname, $extm_id) = @_; 

    $self->throw("Should give defined databasename and member_stable_id as arguments\n") unless (defined $dbname && defined $extm_id);

    my $q = "SELECT f.family_id, f.stable_id, f.description, 
                    f.release, f.annotation_confidence_score
             FROM family f, family_members fm, external_db edb
             WHERE f.family_id = fm.family_id
             AND fm.external_db_id = edb.external_db_id
             AND edb.name = '$dbname' 
             AND fm.external_member_id = '$extm_id'"; 

    return $self->_get_families($q);
}

=head2 fetch_by_dbname_taxon_member

 Arg [1]    : string $dbname
 Arg [2]    : int $taxon_id
 Arg [3]    : string $member_stable_id
 Example    : $fams = $db->fetch_of_dbname_taxon_member('ENSEMBLGENE', '9606', 'ENSG000001101002');
 Description: find the family to which the given database, taxon_id and member_stable_id belong
 Returntype : an array reference of Bio::EnsEMBL::ExternalData::Family::Family objects
              (could be empty or contain more than one Family in the case of ENSEMBLGENE only)
 Exceptions : when missing arguments
 Caller     : general

=cut

sub fetch_by_dbname_taxon_member { 
    my ($self, $dbname, $taxon_id, $extm_id) = @_; 

    $self->throw("Should give defined databasename and taxon_id and member_stable_id as arguments\n") unless (defined $dbname && defined $taxon_id && defined $extm_id);

    my $q = "SELECT f.family_id, f.stable_id, f.description, 
                    f.release, f.annotation_confidence_score
             FROM family f, family_members fm, external_db edb
             WHERE f.family_id = fm.family_id
             AND fm.external_db_id = edb.external_db_id
             AND edb.name = '$dbname' 
             AND fm.external_member_id = '$extm_id'
             AND fm.taxon_id = $taxon_id"; 

    return $self->_get_families($q);
}

=head2 fetch_by_description_with_wildcards

 Arg [1]    : string $description
 Arg [2]    : int $wildcard (optional)
              if set to 1, wildcards are added and the search is a slower LIKE search
 Example    : $fams = $FamilyAdaptor->fetch_by_description_with_wildcards('REDUCTASE',1);
 Description: simplistic substring searching on the description to get the families
              matching the description. (The search is currently case-insensitive;
              this may change if SPTR changes to case-preservation)
 Returntype : an array reference of Bio::EnsEMBL::ExternalData::Family::Family objects
 Exceptions : none
 Caller     : general

=cut

sub fetch_by_description_with_wildcards{ 
    my ($self,$desc,$wildcard) = @_; 

    my $query = $desc;
    my $q;
    if ($wildcard) {
	$query = "%"."\U$desc"."%";
        $q = 
	    "SELECT f.family_id, f.stable_id, f.description, 
                    f.release, f.annotation_confidence_score
               FROM family f
              WHERE f.description LIKE '$query'";
    }
    else {
	$q = 
	    "SELECT f.family_id, f.stable_id, f.description, 
                    f.release, f.annotation_confidence_score
               FROM family f
              WHERE f.description = '$query'";
    }
    return $self->_get_families($q);
}

=head2 fetch_all

 Args       : none
 Example    : $FamilyAdaptor->fetch_all
 Description: get all the families from a family database
 Returntype : an array reference of Bio::EnsEMBL::ExternalData::Family::Family objects
 Exceptions : none
 Caller     : general

=cut


sub fetch_all { 
    my ($self) = @_; 

    my $q = 
      "SELECT f.family_id, f.stable_id, f.description, 
              f.release, f.annotation_confidence_score
       FROM family f";
    return $self->_get_families($q);
}


=head2 fetch_Taxon_by_dbname_dbID

 Arg [1]    : string $dbname
              Either "ENSEMBLGENE", "ENSEMBLPEP" or "SPTR" 
 Arg [2]    : int dbID
              a family_id
 Example    : $FamilyAdaptor->fetch_Taxon_by_dbname('ENSEMBLGENE',1)
 Description: get all the taxons that belong to a particular database and family_id
 Returntype : an array reference of Bio::EnsEMBL::ExternalData::Family::Taxon objects
              (which may be empty)
 Exceptions : when missing argument
 Caller     : general

=cut

sub fetch_Taxon_by_dbname_dbID {
  my ($self,$dbname,$dbID) = @_;
  
  $self->throw("Should give defined databasename and family_id as arguments\n") unless (defined $dbname && defined $dbID);

  my $q = "SELECT distinct(taxon_id) as taxon_id
           FROM family f, family_members fm, external_db edb
           WHERE f.family_id = fm.family_id
           AND fm.external_db_id = edb.external_db_id 
           AND f.family_id = $dbID
           AND edb.name = '$dbname'"; 
  $q = $self->prepare($q);
  $q->execute;

  my @taxons = ();

  while (defined (my $rowhash = $q->fetchrow_hashref)) {
    my $TaxonAdaptor = $self->db->get_TaxonAdaptor;
    my $taxon = $TaxonAdaptor->fetch_by_taxon_id($rowhash->{taxon_id});
    push @taxons, $taxon;
  }
    
  return \@taxons;

}

=head2 known_databases

 Args       : none
 Example    : $FamilyAdaptor->known_databases
 Description: get all database name, source of the family members
 Returntype : an array reference of string
 Exceptions : none
 Caller     : general

=cut

sub known_databases {
  my ($self) = @_;
  
  if (not defined $self->{_known_databases}) {
      $self->{_known_databases} = $self->_known_databases();
  }
  return $self->{_known_databases};
}
       

=head2 get_max_id

 Args       : none
 Example    : $FamilyAdaptor->get_max_id
 Description: find the higest family_stable_id (ENSFxxx) in this database (needed for mapping). 
 Returntype : string
 Exceptions : none
 Caller     : general

=cut

sub get_max_id {
    my($self, $db) = @_;

    my $q = "select max(stable_id) from family";
    
    $q = $self->prepare($q);
    $q->execute;

    my ( @row ) = $q->fetchrow_array; 
    return $row[0];
}



=head2 fetch_alignment

  Arg [1]    : Bio::EnsEMBL::External::Family::Family $family
  Example    : $family_adaptor->fetch_alignment($family);
  Description: Retrieves the alignment strings for all the members of a 
               family
  Returntype : none
  Exceptions : none
  Caller     : FamilyMember::align_string

=cut

sub fetch_alignment {
  my($self, $family) = @_;

  my $members = $family->get_all_members;
  return unless(@$members);

  my $sth = $self->prepare("SELECT family_member_id, alignment 
                            FROM family_members
                            WHERE family_id = ?");
  $sth->execute($family->dbID);

  #move results of query into hash keyed on family member id
  my %align_hash = map {$_->[0] => $_->[1]} (@{$sth->fetchall_arrayref});
  $sth->finish;

  #set the slign strings for each of the members
  foreach my $member (@$members) {
    $member->alignment_string($align_hash{$member->dbID()});
  }

  return;
}


##################
# internal methods

#internal method used in multiple calls above to build family objects from table data  

sub _get_families {
    my ($self, $q) = @_;

    $q = $self->prepare($q);
    $q->execute;

    my @fams = ();

    while (defined (my $rowhash = $q->fetchrow_hashref)) {
        my $fam = new Bio::EnsEMBL::ExternalData::Family::Family;

        $fam->adaptor($self);
        $fam->dbID($rowhash->{family_id});
        $fam->stable_id($rowhash->{stable_id});
        $fam->description($rowhash->{description});
        $fam->release($rowhash->{release});
        $fam->annotation_confidence_score($rowhash->{annotation_confidence_score});

        push(@fams, $fam);
    }
    
    return \@fams;                         
}  

# get one or no family, given some query
sub _get_family {
    my ($self, $q) = @_;
    
    my $fams = $self->_get_families($q);
    
    if (scalar @{$fams} > 1) {
      $self->throw("Internal database error, expecting at most one Family.
Check data coherence, e.g. have two families with different family_id have the same stable id.\n");
# as family_id and stable_id are unique keys _get_families should sufficient;
    };

    return $fams->[0];  
}              

 

sub _known_databases {
  my ($self) = @_;
  
  my $q = 
    "SELECT name FROM external_db";
  $q = $self->prepare($q);
  $q->execute;

  my @res= ();
  while ( my ( @row ) = $q->fetchrow_array ) {
        push @res, $row[0];
  }
  $self->throw("didn't find any database") if (int(@res) == 0);
  return \@res;
}

###############
# store methods

=head2 store

 Arg [1]    : Bio::EnsEMBL::ExternalData:Family::Family $fam
 Example    : $FamilyAdaptor->store($fam)
 Description: Stores a family object into a family  database
 Returntype : int 
              been the database family identifier, if family stored correctly
 Exceptions : when isa if Arg [1] is not Bio::EnsEMBL::ExternalData::Family::Family
 Caller     : general

=cut

sub store {
  my ($self,$fam) = @_;

  $fam->isa('Bio::EnsEMBL::ExternalData::Family::Family') ||
    $self->throw("You have to store a Bio::EnsEMBL::ExternalData::Family::Family object, not a $fam");

  my $q = "SELECT family_id from family where stable_id = ?";
  $q = $self->prepare($q);
  $q->execute($fam->stable_id);
  my $rowhash = $q->fetchrow_hashref;
  if ($rowhash->{family_id}) {
    return $rowhash->{family_id};
  }

  $q = "INSERT INTO family (stable_id, description, release, annotation_confidence_score) VALUES (?,?,?,?)";
  $q = $self->prepare($q);
  $q->execute($fam->stable_id,$fam->description,$fam->release,$fam->annotation_confidence_score);
  $fam->dbID($q->{'mysql_insertid'});

  my $member_adaptor = $self->db->get_FamilyMemberAdaptor;
  foreach my $member (@{$fam->get_all_members}) {
    $member->external_db_id($self->_store_db_if_needed($member->database));
    $member_adaptor->store($fam->dbID,$member);
  }

  return $fam->dbID;
}

sub _store_db_if_needed {
  my ($self,$dbname) = @_;
  
  my $q = "select external_db_id from external_db where name = ?";
  $q = $self->prepare($q);
  $q->execute($dbname);
  my $rowhash = $q->fetchrow_hashref;
  if ($rowhash->{external_db_id}) {
    return $rowhash->{external_db_id};
  } else {
    $q = "INSERT INTO external_db (name) VALUES (?)";
    $q = $self->prepare($q);
    $q->execute($dbname);
    return $q->{'mysql_insertid'};
  }
}


=head2 convert_store_family

 Arg [1]    : -family => \@Bio::Cluster::SequenceFamily
 Example    : $FamilyAdaptor->convert_store_family(-family=>\@family)
 Description: converts  Bio::Cluster::SequenceFamily objects into a Bio::EnsEMBL::ExternalData::Family objects
              and store.
 Returntype : array of dbIDs 
              been the database family identifier, if family stored correctly
 Exceptions : 
 Caller     : general

=cut

sub convert_store_family {
    my($self,@args) = @_;
    my ($family) = $self->_rearrange([qw(FAMILY)],@args);

    my %conf = %Bio::EnsEMBL::ExternalData::Family::FamilyConf::FamilyConf;
    my @ens_species = split(',',$conf{'ENSEMBL_SPECIES'});
    my $family_prefix = $conf{"FAMILY_PREFIX"};
    my $release       = $conf{'RELEASE'};
    my $ext_db_name   = $conf{'EXTERNAL_DBNAME'};
    my %taxon_species;
    my @id;

    my @taxon_str;
    foreach my $sp(@ens_species){
      $sp = uc $sp;
      push @taxon_str, $conf{"$sp"."_TAXON"};
    }
    my  %ens_taxon_info = $self->_setup_ens_taxon(@taxon_str);


    my @ens_fam;
    my $family_count = $conf{"FAMILY_START"} || 1;
    foreach my $fam (@{$family}){
      my @members = $fam->get_members;
      my @ens_mem;
      foreach my $mem (@members){
        my $taxon = $mem->species;
        if(!$taxon->ncbi_taxid){
            foreach my $key (keys %ens_taxon_info){
              if($mem->display_id =~/$key/){
                my %taxon_hash = %{$ens_taxon_info{$key}};
                my @class = split(':',$taxon_hash{'taxon_classification'});
                $taxon = Bio::EnsEMBL::ExternalData::Family::Taxon->new(-classification=>\@class);
                $taxon->common_name($taxon_hash{'taxon_common_name'});
                $taxon->sub_species($taxon_hash{'taxon_sub_species'});
                $taxon->ncbi_taxid($taxon_hash{'taxon_id'});
                last;
              }
            }
        }

        bless $taxon,"Bio::EnsEMBL::ExternalData::Family::Taxon";

        my $member = Bio::EnsEMBL::ExternalData::Family::FamilyMember->new();
        $member->family_id($fam->family_id);
        my ($annot) = $mem->annotation->get_Annotations('dblink');
        $member->database(uc $annot->database);
        $member->stable_id($mem->display_name);
        $taxon->ncbi_taxid || $self->throw($mem->id." has no taxon id!");
        $self->db->get_TaxonAdaptor->store_if_needed($taxon);
	$member->taxon_id($taxon->ncbi_taxid);

        $member->adaptor($self);

        $member->database(uc $ext_db_name) if (! defined $member->database || $member->database eq "");
        push @ens_mem, $member;
      }
      my $stable_id = sprintf ("$family_prefix%011.0d",$family_count);
      $family_count++;
      my $ens_fam= new Bio::EnsEMBL::ExternalData::Family::Family(-stable_id=>$stable_id,
                                                                  -members=>\@ens_mem,
                                                                  -description=>$fam->description,
                                                                  -score=>$fam->annotation_score,
                                                                  -adpator=>$self);

      $ens_fam->release($release);
      #$ens_fam->annotation_confidence_score($fam->annotation_score);

      push @id,$self->store($ens_fam);
  }

 return @id;

}

#process ensembl taxon information for FamilyConf.pm
sub _setup_ens_taxon {
    my ($self,@taxon_str) = @_;

    my %hash;
    foreach my $str(@taxon_str){

      $str=~s/=;/=undef;/g;
      my %taxon = map{split '=',$_}split';',$str;
      my $prefix = $taxon{'PREFIX'}; 
      delete $taxon{'PREFIX'};
      $hash{$prefix} = \%taxon;
    }
    return %hash;
}


###########################################
#
# Deprecated methods. Will be deleted soon.

sub get_Family_by_id  {
  my ($self, $id) = @_;

  $self->warn("FamilyAdaptor->get_Family_by_id is a deprecated method!
Calling FamilyAdaptor->fetch_by_dbID instead!");

  return $self->fetch_by_dbID($id);
}

sub get_Family_of_Ensembl_gene_id {
  my ($self, $eid) = @_;

  $self->warn("FamilyAdaptor->get_Family_of_Ensembl_gene_id is a deprecated method!
Calling FamilyAdaptor->fetch_by_dbname_id instead!");

  return $self->fetch_by_dbname_id('ENSEMBLGENE', $eid);
}

sub get_Family_of_Ensembl_pep_id {
  my ($self, $eid) = @_;

  $self->warn("FamilyAdaptor->get_Family_of_Ensembl_pep_id is a deprecated method!
Calling FamilyAdaptor->fetch_by_dbname_id instead!");

  return $self->fetch_by_dbname_id('ENSEMBLPEP', $eid);
}

sub all_Families {
  my ($self) = @_;

  $self->warn("FamilyAdaptor->all_Families is a deprecated method!
Calling FamilyAdaptor->fetch_all instead!");
  
  return $self->fetch_all;

}


1;
