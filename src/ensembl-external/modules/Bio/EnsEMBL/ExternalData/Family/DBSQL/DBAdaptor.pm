
=head1 NAME - Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor

=head1 SYNOPSIS

    $db = Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor->new(
								    -user   => 'myusername',
								    -dbname => 'familydb',
								    -host   => 'myhost',
								   );

    $family_adaptor  = $db->get_FamilyAdaptor;
    $familymember_adaptor  = $db->get_FamilyMemberAdaptor;
    $taxon_adaptor  = $db->get_TaxonAdaptor;

=head1 DESCRIPTION

This object represents a database that is implemented somehow (you shouldnt
care much as long as you can get the object). You can pull
out other objects such as Family, FamilyMember, Taxon through their respective adaptors.

=head1 CONTACT

Post questions to the EnsEMBL development list <ensembl-dev@ebi.ac.uk>

=cut

package Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::DBSQL::DBConnection;

@ISA = qw( Bio::EnsEMBL::DBSQL::DBConnection );

=head2 new

  Arg [..]   : list of named arguments.	 See Bio::EnsEMBL::DBConnection.
  [-CONF_FILE] optional name of a file containing configuration
		information for family genome databases.  If databases are
		not added in this way, then they should be added via the
		method add_DBAdaptor.
  Example    :	$db = new Bio::EnsEMBL::ExternalDataba::Family::DBSQL::DBAdaptor
                           ( -user   => 'root',
                             -dbname => 'pog',
                             -host   => 'caldy',
                             -driver => 'mysql',
                             -conf_file => 'conf.pl');
  Description: Creates a new instance of a DBAdaptor for the family database.
  Returntype : Bio::EnsEMBL::ExternalData::Family::DBAdaptor
  Exceptions : none
  Caller     : general

=cut

sub new {
  my ($class, @args) = @_;

  my $self = $class->SUPER::new(@args);

  my ($conf_file) = $self->_rearrange(['CONF_FILE'], @args);

  $self->{'genomes'} = {};

  if($conf_file) {
    #read configuration file from disk
    my @conf = @{do $conf_file};

    foreach my $genome (@conf) {
      my ($species, $assembly, $db_hash) = @$genome;
      my $db;

      my $module = $db_hash->{'module'};
      my $mod = $module;

      eval {
        # require needs /'s rather than colons
        if ( $mod =~ /::/ ) {
          $mod =~ s/::/\//g;
        }
        require "${mod}.pm";

        $db = $module->new(-dbname => $db_hash->{'dbname'},
			   -host   => $db_hash->{'host'},
			   -user   => $db_hash->{'user'},
			   -pass   => $db_hash->{'pass'},
			   -port   => $db_hash->{'port'},
			   -driver => $db_hash->{'driver'});
      };

      if($@) {
        $self->throw("could not load module specified in configuration " .
          "file:$@");
      }

      unless($db && ref $db && $db->isa('Bio::EnsEMBL::DBSQL::DBConnection')) {
        $self->throw("[$db] specified in conf file is not a " .
                     "Bio::EnsEMBL::DBSQL::DBConnection");
      }

      $self->{'genomes'}->{"$species:$assembly"} = $db;
    }
  }

  return $self;
}


=head2 add_db_adaptor

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection
  Example    : $family_db->add_db_adaptor($homo_sapiens_db);
  Description: Adds a genome-containing database to compara.  This database
		can be used by some family methods to obtain sequence for 
                peptides that analysis has been performed on.
		The database adaptor argument must define the get_MetaContainer 
		argument
		so that species name and assembly type information can be
		extracted from the database.
  Returntype : none
  Exceptions : Thrown if the argument is not a Bio::EnsEMBL::DBConnection
		or if the argument does not implement a get_MetaContainer
		method.
  Caller	: general

=cut

sub add_db_adaptor {
  my ($self, $dba) = @_;

  unless($dba && ref $dba && $dba->isa('Bio::EnsEMBL::DBSQL::DBConnection')) {
    $self->throw("dba argument must be a Bio::EnsEMBL::DBSQL::DBConnection\n" .
		 "not a [$dba]");
  }

  my $mc = $dba->get_MetaContainer;

  my $species = $mc->get_Species->binomial;
  my $assembly = $mc->get_default_assembly;

  $self->{'genomes'}->{"$species:$assembly"} = $dba;
}


=head2 get_db_adaptor

  Arg [1]    : string $species
		the name of the species to obtain a genome DBAdaptor for.
  Arg [2]    : string $assembly
		the name of the assembly to obtain a genome DBAdaptor for.
  Example    : $hs_db = $db->get_db_adaptor('Homo sapiens','NCBI31');
  Description: Obtains a DBAdaptor for the requested genome if it has been
		specified in the configuration file passed into this objects
		constructor, or subsequently added using the add_genome
		method.	If the DBAdaptor is not available (i.e. has not
		been specified by one of the abbove methods) undef is returned.
  Returntype : Bio::EnsEMBL::DBSQL::DBConnection
  Exceptions : none
  Caller	: Bio::EnsEMBL::Compara::GenomeDBAdaptor

=cut

sub get_db_adaptor {
  my ($self, $species, $assembly) = @_;

  unless($species && $assembly) {
    $self->throw("species and assembly arguments are required\n");
  }

  return $self->{'genomes'}->{"$species:$assembly"};
}



=head2 get_FamilyAdaptor

 Args       : none
 Example    : my $family_adaptor = $db->get_FamilyAdaptor;
 Description: retrieve the FamilyAdaptor which is used for reading and writing
              Bio::EnsEMBL::ExternalData::Family::Family objects from and to 
              the SQL database.
 Returntype : Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyAdaptor
 Exceptions : none
 Caller     : general

=cut 

sub get_FamilyAdaptor {
  my ($self) = @_;
  
  return $self->_get_adaptor
    ( "Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyAdaptor" );
}

=head2 get_FamilyMemberAdaptor

 Args       : none
 Example    : my $familymember_adaptor = $db->get_FamilyMemberAdaptor;
 Description: retrieve the FamilyMemberAdaptor which is used for reading and writing
              Bio::EnsEMBL::ExternalData::Family::FamilyMember objects from and to 
              the SQL database.
 Returntype : Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyMemberAdaptor
 Exceptions : none
 Caller     : general

=cut 

sub get_FamilyMemberAdaptor {
  my ($self) = @_;
  
  return $self->_get_adaptor
    ( "Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyMemberAdaptor" );
}

=head2 get_TaxonAdaptor

 Args       : none
 Example    : my $taxon__adaptor = $db->get_TaxonAdaptor;
 Description: retrieve the TaxonAdaptor which is used for reading and writing
              Bio::EnsEMBL::ExternalData::Family::Taxon objects from and to 
              the SQL database.
 Returntype : Bio::EnsEMBL::ExternalData::Family::DBSQL::TaxonAdaptor
 Exceptions : none
 Caller     : general

=cut 

sub get_TaxonAdaptor {
  my ($self) = @_;
  
  return $self->_get_adaptor
    ( "Bio::EnsEMBL::ExternalData::Family::DBSQL::TaxonAdaptor" );
}

=head2 get_GenomeDBAdaptor

 Args	    : none
 Example    : my $genome_dba = $db->get_GenomeDBAdaptor;
 Description: Retrieves a genome db adaptor which can be used to retrieve
              genome containing databases
 Returntype : Bio::EnsEMBL::ExternalData::Family::DBSQL::GenomeDBAdaptor
 Exceptions : none
 Caller	    : general

=cut

sub get_GenomeDBAdaptor {
  my ($self) = @_;

  return $self->_get_adaptor
    ( "Bio::EnsEMBL::ExternalData::Family::DBSQL::GenomeDBAdaptor" );
}


1;
