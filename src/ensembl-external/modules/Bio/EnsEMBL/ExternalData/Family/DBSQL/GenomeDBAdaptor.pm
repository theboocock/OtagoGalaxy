#
# Ensembl module for Bio::EnsEMBL::ExternalData::Family::GenomeDBAdaptor
#
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

Bio::EnsEMBL::Compara::DBSQL::GenomeDBAdaptor

=head1 SYNOPSIS

my $genome_db_adaptor = $family_db->get_GenomeDBAdaptor();
my $genome_db = $genome_db_adaptor->fetch_by_dbID(1);

=head1 DESCRIPTION

A database adaptor used to retrieve genome db objects from the database

=cut

package Bio::EnsEMBL::ExternalData::Family::DBSQL::GenomeDBAdaptor;
use vars qw(@ISA);
use strict;


use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Family::GenomeDB;


@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


=head2 fetch_by_dbID

  Arg [1]    : int $dbid
  Example    : $genome_db = $gdba->fetch_by_dbID(1);
  Description: Retrieves a GenomeDB object via its internal identifier
  Returntype : Bio::EnsEMBL::Compara::GenomeDB
  Exceptions : none
  Caller     : general

=cut

sub fetch_by_dbID{
   my ($self,$dbid) = @_;

   if( !defined $dbid) {
       $self->throw("dbid arg is required");
   }

   my $sth = $self->prepare("SELECT name, taxon_id, assembly 
                             FROM   genome_db
                             WHERE  genome_db_id = ?");

   $sth->execute($dbid);

   my ($name, $taxon_id, $assembly) = $sth->fetchrow_array();

   $self->throw("no genome_db with dbID=[$dbid] exists") 
     unless($name || $taxon_id || $assembly);

   my $dba = $self->db->get_db_adaptor($name, $assembly);

   if(!$dba) {
     $self->throw("Could not obtain DBAdaptor for dbID [$dbid].\n" .
		  "Genome DBAdaptor for name=[".$name."], ".
		  "assembly=[" . $assembly."] must be loaded using " .
		  "config file or\n" .
	   "Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor::add_genome");
   }

   my $gdb = Bio::EnsEMBL::ExternalData::Family::GenomeDB->new
     ($dba, $name, $assembly, $taxon_id, $dbid);

   $gdb->adaptor($self);

   return $gdb;
}


=head2 fetch_all

  Args       : none
  Example    : none
  Description: gets all GenomeDBs for this compara database
  Returntype : listref Bio::EnsEMBL::Compara::GenomeDB
  Exceptions : none
  Caller     : general

=cut

sub fetch_all {
  my ( $self ) = @_;

  my $sth = $self->prepare("SELECT genome_db_id, name, taxon_id, assembly 
                            FROM   genome_db");
  
  $sth->execute();

  my @gdbs;
  my ($dbID, $name, $taxon_id, $assembly);
  while(($dbID, $name, $taxon_id, $assembly) = $sth->fetchrow_array()) {
    
    my $dba = $self->db->get_db_adaptor($name, $assembly);

    if(!$dba) {
      $self->throw("Could not obtain DBAdaptor for dbID [$dbID].\n" .
		   "Genome DBAdaptor for name=[".$name."], ".
		   "assembly=[" . $assembly."] must be loaded using " .
		   "config file or\n" .
	   "Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor::add_genome");
    }

    my $gdb = Bio::EnsEMBL::ExternalData::Family::GenomeDB->new
      ($dba, $name, $assembly, $taxon_id, $dbID);
    
    $gdb->adaptor($self);

    push @gdbs, $gdb;
  }

  return \@gdbs;
} 



=head2 fetch_by_name_assembly

  Arg [1]    : string $name
  Arg [2]    : string $assembly
  Example    : $gdb = $gdba->fetch_by_name_assembly("Homo sapiens", 'NCBI_31');
  Description: Retrieves a genome db using the name of the species and
               the assembly version.
  Returntype : Bio::EnsEMBL::Compara::GenomeDB
  Exceptions : thrown if GenomeDB of name $name and $assembly cannot be found
  Caller     : general

=cut

sub fetch_by_name_assembly{
   my ($self, $name, $assembly) = @_;

   unless($name && $assembly) {
     $self->throw('name and assembly arguments are required');
   }

   my $sth = $self->prepare(
	     "SELECT genome_db_id, taxon_id
              FROM genome_db
              WHERE name = ? AND assembly = ?");

   $sth->execute($name, $assembly);

   my ($dbID, $taxon_id) = $sth->fetchrow_array();

   if( !defined $dbID ) {
       $self->throw("No GenomeDB with this name [$name] and " .
		    "assembly [$assembly]");
   }

   my $dba = $self->db->get_db_adaptor($name, $assembly);

   if(!$dba) {
     $self->throw("Could not obtain DBAdaptor for dbID [$dbID].\n" .
		  "Genome DBAdaptor for name=[".$name."], ".
		  "assembly=[" . $assembly."] must be loaded using " .
		  "config file or\n" .
	   "Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor::add_genome");
   }

   my $gdb = Bio::EnsEMBL::ExternalData::Family::GenomeDB->new
     ($dba, $name, $assembly, $taxon_id, $dbID);

   $gdb->adaptor($self);

   return $gdb;
}



=head2 fetch_by_taxon_id

  Arg [1]    : int $taxon_id
  Example    : $gdb = $gdba->fetch_by_name_taxon_id("Homo sapiens", '9606');
  Description: Retrieves a genome db using the taxon_id.  This does not
               currently allow for multiple assemblies of the same genome
               as compara does, but may be changed in the future.
  Returntype : Bio::EnsEMBL::Compara::GenomeDB
  Exceptions : thrown if GenomeDB of name $name and $assembly cannot be found
  Caller     : general

=cut

sub fetch_by_taxon_id {
   my ($self, $taxon_id) = @_;

   unless($taxon_id) {
     $self->throw('taxon_id arg is required');
   }

   my $sth = $self->prepare(
	     "SELECT genome_db_id, name, assembly
              FROM genome_db
              WHERE taxon_id = ?");

   $sth->execute($taxon_id);

   my ($dbID, $name, $assembly) = $sth->fetchrow_array();

   if( !defined $dbID ) {
       $self->throw("No GenomeDB with taxon_id [$taxon_id]");
   }

   my $dba = $self->db->get_db_adaptor($name, $assembly);

   if(!$dba) {
     $self->throw("Could not obtain DBAdaptor for dbID [$dbID].\n" .
		  "Genome DBAdaptor for name=[".$name."], ".
		  "assembly=[" . $assembly."] must be loaded using " .
		  "config file or\n" .
	   "Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor::add_genome");
   }

   my $gdb = Bio::EnsEMBL::ExternalData::Family::GenomeDB->new
     ($dba, $name, $assembly, $taxon_id, $dbID);

   $gdb->adaptor($self); 

   return $gdb;
}





=head2 store

  Arg [1]    : Bio::EnsEMBL::Compara::GenomeDB $gdb
  Example    : $gdba->store($gdb);
  Description: Stores a genome database object in the compara database if
               it has not been stored already.  The internal id of the
               stored genomeDB is returned.
  Returntype : int
  Exceptions : thrown if the argument is not a Bio::EnsEMBL::Compara:GenomeDB
  Caller     : general

=cut

sub store{
  my ($self,$gdb) = @_;

  $self->throw("Must have genomedb arg [$gdb]") unless($gdb);

  my $name = $gdb->name;
  my $assembly = $gdb->assembly;
  my $taxon_id = $gdb->taxon_id;

  unless($name && $assembly && $taxon_id) {
    $self->throw("genome db must have a name, assembly, and taxon_id");
  }

  my $sth = $self->prepare('
      SELECT genome_db_id
      FROM genome_db
      WHERE name = ? and assembly = ?');

  $sth->execute($name, $assembly);
  
  my $dbID = $sth->fetchrow_array();

  if(!$dbID) {
    #if the genome db has not been stored before, store it now
    my $sth = $self->prepare("
        INSERT into genome_db (name,assembly,taxon_id)
        VALUES (?,?,?)
      ");

    $sth->execute($name, $assembly, $taxon_id);
    $dbID = $sth->{'mysql_insertid'};
  }

  #update the genomeDB object so that it's dbID and adaptor are set
  $gdb->dbID($dbID);
  $gdb->adaptor($self);

  return $dbID;
}


1;

