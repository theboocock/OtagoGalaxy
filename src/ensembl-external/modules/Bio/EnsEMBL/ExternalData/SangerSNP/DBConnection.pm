package Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection;

=head1 NAME

Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection -
Database connection object for a SangerSNP database

=head1 SYNOPSIS

    $dbc = Bio::EnsEMBL::DBSQL::DBConnection->new(
        -user    => 'anonymous',
        -dbname  => 'snp',
        -host    => 'ocs4',
        -driver  => 'Oracle',
        -species => 'Homo Sapiens',
        -group   => 'sangersnp'
        );

   SQL statements should be created/executed through
   this modules prepare() and do() methods.

   $sth = $dbc->prepare( "SELECT something FROM yourtable" );
   $sth->execute();
   # do something with rows returned ...
   $sth->finish();

=head1 DESCRIPTION

  This class is a wrapper around DBIs datbase handle.

  Generally this class will be used through one of the object adaptors or the
  Bio::EnsEMBL::Registry and will not be instantiated directly.

=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 AUTHOR

Steve Searle <searle@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

use strict;

use DBI;
use Bio::EnsEMBL::DBSQL::DBConnection;
use Bio::EnsEMBL::Utils::Exception qw(throw info warning);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::DBSQL::DBConnection);

=head2 new

  Arg [DBNAME] : string
                 The name of the database to connect to.
  Arg [HOST] : (optional) string
               The domain name of the database host to connect to.  
               'localhost' by default. 
  Arg [USER] : string
               The name of the database user to connect with 
  Arg [PASS] : (optional) string
               The password to be used to connect to the database
  Arg [PORT] : int
               The port to use when connecting to the database
  Arg [DRIVER] : (optional) string
                 The type of database driver to use to connect to the DB
                 mysql by default.
  Arg [DBCONN] : (optional)
                 Open another handle to the same database as another connection
                 If this argument is specified, no other arguments should be
                 specified.
  Example    : $dbc = Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection->new
                  (-user   => 'anonymous',
                   -dbname => 'snp',
                   -host   => 'ocs4',
                   -driver => 'Oracle');

  Description: Constructor for a DatabaseConenction. Any adaptors that require
               database connectivity should inherit from this class.
  Returntype : Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection
  Exceptions : thrown if USER or DBNAME are not specified, or if the database
               cannot be connected to.
  Caller     : Bio::EnsEMBL::::Utils::ConfigRegistry (for newer code using the
               registry), Bio::EnsEMBL::DBSQL::DBAdaptor (for old style code)

=cut

sub new {
    my $class = shift;
    my ($db, $host, $driver, $user, $password, $port, $dbconn) =
        rearrange([qw(DBNAME HOST DRIVER USER PASS PORT DBCONN )], @_);

    my $self = {};
    bless $self, $class;

    if($dbconn) {
        if($db || $host || $driver || $password || $port) {
            throw("Cannot specify other arguments when -DBCONN argument used.");
        }
        $self->dbname($dbconn->dbname);
        $self->username($dbconn->username);
        $self->host($dbconn->host);
        $self->password($dbconn->password);
        $self->port($dbconn->port);
        $self->driver($dbconn->driver);
    } else {
        $db   || throw("-DBNAME argument is required.");
        $user || throw("-USER argument is required.");

        $driver ||= 'Oracle';

        $self->username($user);
        $self->host($host);
        $self->dbname($db);
        $self->password($password);
        $self->driver($driver);
    }
    return $self;
}

=head2 connect

  Example    : $dbc->connect
  Description: Connects to the database using the connection attribute 
               information.
  Returntype : none
  Exceptions : thrown if it can't connect to database
  Caller     : $self->new, $self->db_handle

=cut

sub connect {
    my $self = shift;
    return if($self->connected);
    $self->connected(1);

    if(defined($self->db_handle) and $self->db_handle->ping) {
        warning("unconnected db_handle is still pingable, reseting connected boolean\n");
    }

    my $dbh;
    my $dsn;

    if ($self->driver eq 'Oracle') {
      $dsn = "DBI:" . $self->driver . ":";
      eval {
          $dbh = DBI->connect($dsn,
                              $self->username . "\@" . $self->dbname,
                              $self->password,
                              { 'RaiseError' => 1, 'PrintError' => 0, 'AutoCommit' => 1 });
      };
    } else {
      $dsn = "DBI:" . $self->driver() .
            ":database=". $self->dbname() .
            ";host=" . $self->host() .
            ";port=" . $self->port();

     eval{ $dbh = DBI->connect($dsn, $self->username(), $self->password(), {'RaiseError' => 1}); };
   }


    if(!$dbh || $@ || !$dbh->ping) {
        warn("Could not connect to database " . $self->dbname .
                " as user " . $self->username .
                " using [$dsn] as a locator:\n" . $DBI::errstr);
        throw("Could not connect to database " . $self->dbname .
                " as user " . $self->username .
                " using [$dsn] as a locator:\n" . $DBI::errstr);
    }

    $self->db_handle($dbh);
}

1;
