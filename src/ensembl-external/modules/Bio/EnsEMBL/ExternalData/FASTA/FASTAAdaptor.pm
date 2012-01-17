
=head1 NAME

FASTAAdaptor - DESCRIPTION of Object

  This object represents a database of fasta sequences.

=head1 SYNOPSIS

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::FASTA::FASTAAdaptor;

$db = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
                       -user   => 'ensro',
                       -dbname => 'fasta_8_1',
                       -host   => 'ecs3d',
                       -driver => 'mysql',
                      );
my $fasta_adtor = Bio::EnsEMBL::ExternalData::FASTA::FASTAAdaptor->new($db);

$seqobj  = $fasta_adtor->fetch_fasta_by_id('AP000869.1');  # fasta id


=head1 DESCRIPTION

This module is an entry point into a database of fasta sequences,

The objects can only be read from the database, not written. (They are
loaded using a separate perl script).

=head1 CONTACT

 Tony Cox <Lavc@sanger.ac.uk>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::ExternalData::FASTA::FASTAAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inheriets from Bio::Root::Object

use Bio::Root::Object;
use Bio::Seq;
use DBI;

use Bio::EnsEMBL::DBSQL::BaseAdaptor;

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);

=head2 insert_fasta_record

 Title   : insert_fasta_record
 Usage   : $db->insert_fasta_record($tablename, $seq);
 Function: 
 Example :
 Returns : 
 Args  : table, bioperl seq obj

=cut
sub insert_fasta_record  {
  my ($self, $table, $seq, $parser) = @_;
  if( $parser && ref($parser) ne "CODE" ){ die( "Parser not a ref" ) }
  if($parser){
    #print STDERR "BEFORE: $id ";
    my $id = &$parser($seq->id());
    $id || ( warn( "$seq has no parsable ID!" ) && return );
    $seq->id($id);
    #print STDERR "AFTER: ",$seq->id(),"\n";
  }
  
  my $desc = $seq->desc();
  my $data = $seq->primary_seq->seq();
  my $id = $seq->id();
  
  my $sql =qq( INSERT INTO 
          $table
         VALUES 
           (NULL,"$id","$desc","$data")
        );
  
  my $rv;
  eval{
    my $sth = $self->prepare($sql);
    $rv = $sth->execute();
  };
  if($@){
  warn("Error inserting record $id:\n$@\n");
  }
  return $rv;
}

sub delete_fasta_record  {
  my ($self, $table, $seq) = @_;
  
  my $id = $seq->id();

  my $sql =qq( DELETE FROM 
          $table
         WHERE 
           id="$id"
        );
  my $sth = $self->prepare($sql);
  $sth->execute();
}


sub insert_fasta_metadata  {
  my ($self,$table,$title,$desc,$methods,$credits,$links) = @_;
  
  my $meta = "${table}_meta";

  my $sql =qq( INSERT INTO $meta VALUES ("$table","$title","$desc","$methods","$credits","$links"));
        
  my $sth = $self->prepare($sql);
  $sth->execute();
}

=head2 create_fasta_table

 Title   : create_fasta_table
 Usage   : $db->create_fasta_table('foo');
 Function: 
 Example :
 Returns : 
 Args  : id

=cut

sub create_fasta_table  {
  my ($self, $id) = @_;
  
  my $SCHEMA =qq(
  CREATE TABLE $id (
    id int(10) unsigned NOT NULL auto_increment,
    name varchar(40) NOT NULL default '',  
    description varchar(255) NOT NULL default '',  
    sequence mediumtext NOT NULL,
    PRIMARY KEY  (id),
    UNIQUE KEY  (name)
  ) TYPE=MyISAM
  );
  
  my $meta = "${id}_meta";
  
  my $META =qq(
  CREATE TABLE $meta (
    db varchar(40) NOT NULL default '',  
    title varchar(255) NOT NULL default '',  
    description mediumtext NOT NULL,
    methods mediumtext NOT NULL,
    credits mediumtext NOT NULL,
    links mediumtext NOT NULL,
    PRIMARY KEY  (db)
  ) TYPE=MyISAM
  );

  my $sth = $self->prepare($SCHEMA);
  $sth->execute();
  $sth = $self->prepare($META);
  $sth->execute();
  
}


=head2 fetch_fasta_table_metadata

 Title   : fetch_fasta_table_metadata
 Usage   : $db->fetch_fasta_table_metadata('foo');
 Function: 
 Example :
 Returns : 
 Args  : id

=cut

sub fetch_fasta_table_metadata  {
  my ($self, $id) = @_;

  my $meta = "${id}_meta";
  my $q  =qq( SELECT title,description,methods,credits,links FROM $meta);

  my $sth;
  my $rv;
  eval {
    $sth = $self->prepare($q);
    $rv = $sth->execute();
  };
  $@ && ( warn( $@ ) && return );
  if( $rv == 0 ){ warn( "$q returned no rows" ) }
  return $sth->fetchrow_hashref();
}

sub delete_fasta_metadata  {
  my ($self, $id) = @_;

  my $meta = "${id}_meta";
  my $q  =qq( DELETE FROM $meta);
  
  my $sth = $self->prepare($q);
  $sth->execute();
  return();
}


=head2 drop_fasta_table

 Title   : drop_fasta_table
 Usage   : $db->drop_fasta_table('foo');
 Function: 
 Example :
 Returns : 
 Args  : id

=cut

sub drop_fasta_table  {
  my ($self, $id) = @_;
  
  my $sql =qq( DROP TABLE $id );

  eval {
    my $sth = $self->prepare($sql);
    $sth->execute();
  };
  $@ && warn ("Database error! $@\n") and return 0;

  $sql =qq( DROP TABLE ${id}_meta );

  eval {
    my $sth = $self->prepare($sql);
    $sth->execute();
  };
  $@ && warn ("Database error! $@\n") and return 0;
}

=head2 fetch_fasta_by_id

 Title   : fetch_fasta_by_id
 Usage   : $db->fetch_fasta_by_id("my_table", 'AP000869.1');
 Function: 
 Example :
 Returns : a bioperl seq object, empty list otherwise
 Args  : id

=cut

sub fetch_fasta_by_id  {
  my ($self, $table, $id) = @_; 
  warn join (" ",@_);
  return () if( "$id" eq '');
  my $q  =qq( SELECT name,description,sequence FROM $table WHERE name="$id" );
  
#  warn ("SQL: $q\n");
  
  my $sth = $self->prepare($q);
  $sth->execute();
  my $seq;
  my $rowhash = $sth->fetchrow_hashref();
  if($sth->rows() > 0){
    $seq = Bio::Seq->new(
      -id   => $rowhash->{'name'},
      -desc => $rowhash->{'description'},
      -seq  => $rowhash->{'sequence'},
    );
    return($seq);
  } 

  # This is a "heuristic" search for the ID in the decription.
  # Only executes if we can't find the ID.
  # Wish the NCBI would produce parseable bloody fasta lines!
  $q  =qq( SELECT name,description,sequence FROM $table WHERE description like "%$id%");
#  warn ("Second try for fasta for $q!\n");
  $sth = $self->prepare($q);
  $sth->execute();
  $rowhash = $sth->fetchrow_hashref();
  if($sth->rows() > 0){
    $seq = Bio::Seq->new(
      -id        => $rowhash->{'name'},
      -desc        => $rowhash->{'description'},
      -seq       => $rowhash->{'sequence'},
    );
    return($seq);
  } 
  return(); 
}                     

# set/get handle on ensembl database
sub _ensdb {
  my $self = shift;
  $self->{'_ensdb'} = shift if @_;
  return $self->{'_ensdb'};
}


# get/set handle on fasta database
#sub _fastadb {
#  my $self = shift;
#  $self->{'_fastadb'} = shift if @_;
#  return $self->{'_fastadb'};
#}

# get/set handle on fasta database
#sub adaptor {
#  my $self = shift;
#  $self->{'_adaptor'} = shift if @_;
#  return $self->{'_adaptor'};
#}

# set/get handle on fasta database
#sub _db_handle {
#  my $self = shift;
#  $self->{'_db_handle'} = shift if @_;
#  return $self->{'_db_handle'};
#}

#sub DESTROY {
#   my ($self) = @_;
#   if( $self->{'_db_handle'} ) {
#     $self->{'_db_handle'}->disconnect;
#     $self->{'_db_handle'} = undef;
#   }
#}

1;
