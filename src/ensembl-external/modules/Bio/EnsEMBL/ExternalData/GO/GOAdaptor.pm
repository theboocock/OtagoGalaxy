# 
# BioPerl module for Bio::EnsEMBL::ExternalData::GO::GOAdaptor
# 
# Cared for by Tony Cox <avc@sanger.ac.uk>
#
# Copyright EnsEMBL
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

HaplotypeAdaptor - DESCRIPTION of Object

  GO database interface.

=head1 SYNOPSIS

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::GO::GOAdaptor;

  $hapdb = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
                                    -user   => 'ensro',
                                    -dbname => 'haplotype_5_28',
                                    -host   => 'ecs3d',
                                    -driver => 'mysql',
                                              );
  my $go_adtor = Bio::EnsEMBL::ExternalData::GO::GOAdaptor->new($godb);
  my $term = $go_adtor->get_term({acc=>"GO:0005509"});
    printf
      "GO term; name=%s GO ID=%s\n\n",
      $term->name(), $term->public_acc();

  ### You can add the GOAdaptor as an 'external adaptor' to the 'main'
  ### Ensembl database object, then use it as:
  $ensdb = Bio::EnsEMBL::DBSQL::DBAdaptor->new( ... );
  $ensdb->add_ExternalAdaptor('go', $go_adtor);
  # then later on, elsewhere: 
  $go_adtor = $ensdb->get_ExternalAdaptor('go');
  # also available:
  $ensdb->list_ExternalAdaptors();
  $ensdb->remove_ExternalAdaptor('go');

=head1 DESCRIPTION

This module is an entry point into a GO database.

The objects can only be read from the database, not written. (They are
loaded ussing a separate perl script).

For more info, see GO::AppHandle.pm

=head1 CONTACT

 Tony Cox <avc@sanger.ac.uk>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::ExternalData::GO::GOAdaptor;
use vars qw(@ISA $AUTOLOAD);
use strict;

# Object preamble - inherits from Bio::Root::Object

use Bio::Root::Object;
use DBI;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::DBLinkContainerI;
use Bio::Annotation::DBLink;
use GO::AppHandle;
use Bio::EnsEMBL::Root;
use Bio::EnsEMBL::Registry;
my $reg = "Bio::EnsEMBL::Registry";

@ISA = qw(Bio::EnsEMBL::Root GO::AppHandle);

sub new {
    my($class,@args) = @_;

    my $group = "go";
    my $self = {};
    bless $self, $class;

    my ($db,$user,$pass,$host,$port,$driver,$species) = 
      rearrange([qw(
                DBNAME
                USER
                PASS
                HOST
                PORT
                DRIVER
		SPECIES
                )],@args);

    if(!defined($species)){
      $species = "MULTI";
    }
    if(defined($reg->get_alias($species,"no throw"))){
      my $adap = $reg->get_DBAdaptor($species,$group);
      if(defined($adap)){
	return $adap;
      }
    }
    if( ! $driver ) {
	    $driver = 'mysql';
    }
    if( ! $host ) {
	    $host = 'localhost';
    }

    if (! $port ) {
	    $port = 3306;
    }
    if(! $pass ) { $pass =''; } 
    my $dbh ; eval { $dbh= GO::AppHandle->connect(-dbname=>$db,-dbhost=>"$host:$port",-dbuser=>$user,($pass?(-dbauth=>$pass):())); };
    throw("Could not connect to database $db user $user as a locator ($@)") unless $dbh;
    $self->_db_handle($dbh);
    
    $self->dbname($db);
    $self->port($port);
    $self->host($host);
    $self->driver($driver);
    $self->group($group);
    $self->species($species);
    $reg->add_DBAdaptor($species, $group,  $self);

    return $self; # success - we hope!
}
sub db{
  my $self = shift;
  return $self;
}
sub port {
  my ($self, $arg) = @_;

  (defined $arg) && 
    ($self->{_port} = $arg );
  return $self->{_port};
}
sub species {
  my ($self, $arg) = @_;

  (defined $arg) && 
    ($self->{_species} = $arg );
  return $self->{_species};
}
sub group {
  my ($self, $arg) = @_;

  (defined $arg) && 
    ($self->{_group} = $arg );
  return $self->{_group};
}
sub dbname {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_dbname} = $arg );
  $self->{_dbname};
}
sub driver {
  my($self, $arg ) = @_;

  (defined $arg) &&
    ($self->{_driver} = $arg );
  return $self->{_driver};
}


sub host {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_host} = $arg );
  $self->{_host};
}


# evil....
sub AUTOLOAD {
  my $self = shift;
  my @args = @_;
  (my $function = $AUTOLOAD) =~ s/.*:://;
  #print STDERR "Autoloading: $function via ", $self->_db_handle, "\n";
  my $return;
  eval {
    no strict 'vars';
    $return = $self->_db_handle->$function(@args);
  };
  return $return;
}

# retrieve a GO accession using an accession ID (GO::NNNNNNN)
sub fetch_GO_by_accession {

    my ($self,$value) = @_;
    my $term = $self->_db_handle->get_term({acc=>$value});
    
}

# set/get handle on ensembl database
sub _ensdb {

  my ($self,$value) = @_;
  if( defined $value) {$self->{'_ensdb'} = $value;}
  
  return $self->{'_ensdb'};
}

# get/set handle on GO adaptor
sub adaptor {

  my ($self,$value) = @_;
  if( defined $value) {
    $self->{'_adaptor'} = $value;
  }
  return $self->{'_adaptor'};
}

# set/get handle on GO database
sub _db_handle {

  my ($self,$value) = @_;
  if( defined $value) {$self->{'_db_handle'} = $value;}
  return $self->{'_db_handle'};
}

sub dbc { return shift }

sub DESTROY {

   my ($self) = @_;
   if( $self->{'_db_handle'} ) {
       $self->{'_db_handle'}->disconnect;
       $self->{'_db_handle'} = undef;
   }
}

1;
