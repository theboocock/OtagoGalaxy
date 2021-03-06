# $Id: OBDAIndex.pm,v 1.12.2.1 2003/06/28 20:47:16 jason Exp $
#
# BioPerl module for Bio::DB::Flat::OBDAIndex
#
# Cared for by Michele Clamp <michele@sanger.ac.uk>>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Flat::OBDAIndex - Binary search indexing system for sequence files

=head1 SYNOPSIS

This module can be used both to index sequence files and also to retrieve 
sequences from existing sequence files.

=head2 Index creation

    my $sequencefile;  # Some fasta sequence file

Patterns have to be entered to define where the keys are to be
indexed and also where the start of each record.  E.g. for fasta

    my $start_pattern   = "^>";
    my $primary_pattern = "^>(\\S+)";


So the start of a record is a line starting with a E<gt> and the primary
key is all characters up to the first space afterf the E<gt>

A string also has to be entered to defined what the primary key
(primary_namespace) is called.

The index can now be created using 

    my $index = new Bio::DB::Flat::OBDAIndex(
	     -start_pattern   => $start_pattern,
	     -primary_pattern => $primary_pattern,
             -primary_namespace => "ACC",
					     );

To actually write it out to disk we need to enter a directory where the 
indices will live, a database name and an array of sequence files to index.

    my @files = ("file1","file2","file3");

    $index->make_index("/Users/michele/indices","mydatabase",@files);

The index is now ready to use.  For large sequence files the perl
way of indexing takes a *long* time and a *huge* amount of memory.
For indexing things like dbEST I recommend using the C indexer.

=head2 Creating indices with secondary keys

Sometimes just indexing files with one id per entry is not enough.  For
instance you may want to retrieve sequences from swissprot using
their accessions as well as their ids.

To be able to do this when creating your index you need to pass in 
a hash of secondary_patterns which have their namespaces as the keys
to the hash.

e.g. For Indexing something like

ID   1433_CAEEL     STANDARD;      PRT;   248 AA.
AC   P41932;
DT   01-NOV-1995 (Rel. 32, Created)
DT   01-NOV-1995 (Rel. 32, Last sequence update)
DT   15-DEC-1998 (Rel. 37, Last annotation update)
DE   14-3-3-LIKE PROTEIN 1.
GN   FTT-1 OR M117.2.
OS   Caenorhabditis elegans.
OC   Eukaryota; Metazoa; Nematoda; Chromadorea; Rhabditida; Rhabditoidea;
OC   Rhabditidae; Peloderinae; Caenorhabditis.
OX   NCBI_TaxID=6239;
RN   [1]

where we want to index the accession (P41932) as the primary key and the
id (1433_CAEEL) as the secondary id.  The index is created as follows

    my %secondary_patterns;

    my $start_pattern   = "^ID   (\\S+)";
    my $primary_pattern = "^AC   (\\S+)\;";

    $secondary_patterns{"ID"} = "^ID   (\\S+)";

    my $index = new Bio::DB::Flat::OBDAIndex(
                -start_pattern     => $start_pattern,
                -primary_pattern   => $primary_pattern,
                -primary_namespace  => 'ACC',
                -secondary_patterns => \%secondary_patterns);

    $index->make_index("/Users/michele/indices","mydb",($seqfile));

Of course having secondary indices makes indexing slower and more 
of a memory hog.


=head2 Index reading

To fetch sequences using an existing index first of all create your sequence 
object 

    my $index = new Bio::DB::Flat::OBDAIndex(-index_dir => $index_directory,
                                             -dbname    => 'swissprot');

Now you can happily fetch sequences either by the primary key or
by the secondary keys.

    my $entry = $index->get_entry_by_id('HBA_HUMAN');

This returns just a string containing the whole entry.  This is
useful is you just want to print the sequence to screen or write it to a file.

Other ways of getting sequences are

    my $fh = $index->get_stream_by_id('HBA_HUMAN');

This can then be passed to a seqio object for output or converting
into objects.

    my $seq = new Bio::SeqIO(-fh     => $fh,
			     -format => 'fasta');

The last way is to retrieve a sequence directly.  This is the
slowest way of extracting as the sequence objects need to be made.

    my $seq = $index->get_Seq_by_id('HBA_HUMAN');

To access the secondary indices the secondary namespace needs to be known
(use $index-E<gt>secondary_namespaces) and the following call used

    my $seq   = $index->get_Seq_by_secondary('ACC','Q21973');
    my $fh    = $index->get_stream_by_secondary('ACC','Q21973');
    my $entry = $index->get_entry_by_secondary('ACC','Q21973');

=head1 DESCRIPTION

This object allows indexing of sequence files both by a primary key
(say accession) and multiple secondary keys (say ids).  This is
different from the Bio::Index::Abstract (see L<Bio::Index::Abstract>)
which uses DBM files as storage.  This module uses a binary search to
retrieve sequences which is more efficient for large datasets.


=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org             - General discussion
  http://bioperl.org/MailList.shtml - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via
email or the web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Michele Clamp

Email - michele@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal
methods are usually preceded with an "_" (underscore).

=cut

package Bio::DB::Flat::OBDAIndex;

use strict;
use vars qw(@ISA);

use Fcntl qw(SEEK_END SEEK_CUR);
# rather than using tell which might be buffered
sub systell{ sysseek($_[0], 0, SEEK_CUR) }
sub syseof{ sysseek($_[0], 0, SEEK_END) }


use Bio::DB::RandomAccessI;
use Bio::Root::RootI;
use Bio::SeqIO;
use Bio::Seq;

@ISA = qw(Bio::DB::RandomAccessI);

use constant CONFIG_FILE_NAME => 'config.dat';
use constant HEADER_SIZE      => 4;

my @formats = ['FASTA','SWISSPROT','EMBL'];

=head2 new

 Title   : new
 Usage   : For reading 
             my $index = new Bio::DB::Flat::OBDAIndex(
                     -index_dir => '/Users/michele/indices/',
		     -dbname    => 'dbEST',
                     -format    => 'fasta');

           For writing 

             my %secondary_patterns = {"ACC" => "^>\\S+ +(\\S+)"}
             my $index = new Bio::DB::Flat::OBDAIndex(
		     -index_dir          => '/Users/michele/indices',
		     -primary_pattern    => "^>(\\S+)",
                     -secondary_patterns => \%secondary_patterns,
		     -primary_namespace  => "ID");

             my @files = ('file1','file2','file3');

             $index->make_index('mydbname',@files);    


 Function: create a new Bio::DB::Flat::OBDAIndex object
 Returns : new Bio::DB::Flat::OBDAIndex
 Args    : -index_dir          Directory containing the indices
           -primary_pattern    Regexp defining the primary id
           -secondary_patterns A hash ref containing the secondary
                               patterns with the namespaces as keys
           -primary_namespace  A string defining what the primary key
                               is

 Status  : Public

=cut

sub new {
    my($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    bless $self, $class;

    my ($index_dir,$dbname,$format,$primary_pattern,$primary_namespace,
	$start_pattern,$secondary_patterns) =  
	    $self->_rearrange([qw(INDEX_DIR
				  DBNAME
				  FORMAT
				  PRIMARY_PATTERN
				  PRIMARY_NAMESPACE
				  START_PATTERN
				  SECONDARY_PATTERNS)], @args);
    
    $self->index_directory($index_dir);
    $self->database_name     ($dbname);

    if ($self->index_directory && $dbname) {

	$self->read_config_file;
	
	my $fh = $self->primary_index_filehandle;
        my $record_width = $self->read_header($fh);

        $self->record_size($record_width);
    }


    $self->format            ($format);
    $self->primary_pattern   ($primary_pattern);
    $self->primary_namespace ($primary_namespace);
    $self->start_pattern     ($start_pattern);
    $self->secondary_patterns($secondary_patterns);

    return $self;
}

sub new_from_registry {
    my ($self,%config) =  @_;
   
    my $dbname   = $config{'dbname'};
    my $location = $config{'location'};
    
    my $index =  new Bio::DB::Flat::OBDAIndex(-dbname    => $dbname,
					      -index_dir => $location,
					      );
}

=head2 get_Seq_by_id

 Title   : get_Seq_by_id
 Usage   : $obj->get_Seq_by_id($newval)
 Function: 
 Example : 
 Returns : value of get_Seq_by_id
 Args    : newvalue (optional)

=cut

sub get_Seq_by_id {
    my ($self,$id) = @_;
   
    my ($fh,$length) = $self->get_stream_by_id($id);
    
    if (!defined($self->format)) {
	$self->throw("Can't create sequence - format is not defined");
    }
   
    if(!$fh){
      return;
    }
    if (!defined($self->{_seqio})) {
     
	$self->{_seqio} = new Bio::SeqIO(-fh => $fh,
					 -format => $self->format);
    } else {
      
	$self->{_seqio}->fh($fh);
    }
    
    return $self->{_seqio}->next_seq;

}

=head2 get_entry_by_id

 Title   : get_entry_by_id
 Usage   : $obj->get_entry_by_id($newval)
 Function: 
 Example : 
 Returns : 
 Args    : 


=cut

sub get_entry_by_id {
    my ($self,$id) = @_;

    my ($fh,$length) = $self->get_stream_by_id($id);

    my $entry;

    sysread($fh,$entry,$length);

    return $entry;
}


=head2 get_stream_by_id

 Title   : get_stream_by_id
 Usage   : $obj->get_stream_by_id($newval)
 Function: 
 Example : 
 Returns : value of get_stream_by_id
 Args    : newvalue (optional)


=cut

sub get_stream_by_id {
    my ($self,$id) = @_;

    my $indexfh = $self->primary_index_filehandle;

    syseof ($indexfh);

    my $filesize = systell($indexfh);

    my $end = ($filesize-$self->{_start_pos})/$self->record_size;

    my ($newid,$rest,$fhpos) = $self->find_entry($indexfh,0,$end,$id,$self->record_size);

    
    my ($fileid,$pos,$length) = split(/\t/,$rest);

    #print STDERR "OBDAIndex Found id entry $newid $fileid $pos $length:$rest\n";

    if (!$newid) {
      return;
    }

    my $fh = $self->get_filehandle_by_fileid($fileid);
    my $file = $self->{_file}{$fileid};

    open (IN,"<$file");
    $fh = \*IN;

    my $entry;
    
    sysseek($fh,$pos,0);

    return ($fh,$length);
}

=head2 get_Seq_by_acc

 Title   : get_Seq_by_acc
 Usage   : $obj->get_Seq_by_acc($newval)
 Function: 
 Example : 
 Returns : value of get_Seq_by_acc
 Args    : newvalue (optional)


=cut

sub get_Seq_by_acc {
    my ($self,$acc) = @_;

    if ($self->primary_namespace eq "ACC") {
       return $self->get_Seq_by_id($acc);
    } else {
      return $self->get_Seq_by_secondary("ACC",$acc);
    }
}

=head2 get_Seq_by_secondary

 Title   : get_Seq_by_secondary
 Usage   : $obj->get_Seq_by_secondary($newval)
 Function: 
 Example : 
 Returns : value of get_Seq_by_secondary
 Args    : newvalue (optional)


=cut

sub get_Seq_by_secondary {
    my ($self,$name,$id) = @_;

    my @names = $self->secondary_namespaces;

    my $found = 0;
    foreach my $tmpname (@names) {
	if ($name eq $tmpname) {
	    $found = 1;
	}
    }

    if ($found == 0) {
	$self->throw("Secondary index for $name doesn't exist\n");
    }

    my $fh = $self->open_secondary_index($name);

    syseof ($fh);

    my $filesize = systell($fh);

    my $recsize = $self->{_secondary_record_size}{$name};
#    print "Name " . $recsize . "\n";

    my $end = ($filesize-$self->{_start_pos})/$recsize;

#    print "End $end $filesize\n";

    my ($newid,$primary_id,$pos) = $self->find_entry($fh,0,$end,$id,$recsize);

    sysseek($fh,$pos,0);

#    print "Found new id $newid $primary_id\n";    
    # We now need to shuffle up the index file to find the top secondary entry

    my $record = $newid;

    while ($record =~ /^$newid/ && $pos >= 0) {

	$record = $self->read_record($fh,$pos,$recsize);
	$pos = $pos - $recsize;
#	print "Up record = $record:$newid\n";
    }
    
    $pos += $recsize;

#    print "Top position is $pos\n";

    # Now we have to shuffle back down again to read all the secondary entries

    my $current_id = $newid;
    my %primary_id;

    $primary_id{$primary_id} = 1;

    while ($current_id eq $newid) {
	$record = $self->read_record($fh,$pos,$recsize);
	print "Record is :$record:\n";
	my ($secid,$primary_id) = split(/\t/,$record,2);
	$current_id = $secid;

	if ($current_id eq $newid) {
	    $primary_id =~ s/ //g;
	#    print "Primary $primary_id\n";
	    $primary_id{$primary_id} = 1;
	    
	    $pos = $pos + $recsize;
	 #   print "Down record = $record\n";
	}
    }
	
    if (!defined($newid)) {
      return;
    }

    my $entry;

    foreach my $id (keys %primary_id) {
	$entry .= $self->get_Seq_by_id($id);
    }
    return $entry;

}

=head2 read_header

 Title   : read_header
 Usage   : $obj->read_header($newval)
 Function: 
 Example : 
 Returns : value of read_header
 Args    : newvalue (optional)


=cut

sub read_header {
    my ($self,$fh) = @_;

    my $record_width;

    sysread($fh,$record_width,HEADER_SIZE);

    $self->{_start_pos} = HEADER_SIZE;
    $record_width =~ s/ //g;
    $record_width = $record_width * 1;

    return $record_width;
}

=head2 read_record

 Title   : read_record
 Usage   : $obj->read_record($newval)
 Function: 
 Example : 
 Returns : value of read_record
 Args    : newvalue (optional)


=cut

sub read_record {
  my ($self,$fh,$pos,$len) = @_;

  sysseek($fh,$pos,0);

  my $record;
    
  sysread($fh,$record,$len);

  return $record;

}


=head2 find_entry

 Title   : find_entry
 Usage   : $obj->find_entry($newval)
 Function: 
 Example : 
 Returns : value of find_entry
 Args    : newvalue (optional)


=cut

sub find_entry {
    my ($self,$fh,$start,$end,$id,$recsize) = @_;

    my $mid = int(($end+1+$start)/2);
    my $pos = ($mid-1)*$recsize + $self->{_start_pos};

    my ($record) = $self->read_record($fh,$pos,$recsize);
    my ($entryid,$rest)  = split(/\t/,$record,2);

#    print "Mid $recsize $mid $pos:$entryid:$rest:$record\n";
#    print "Entry :$id:$entryid:$rest\n";

    
    my ($first,$second) = sort { $a cmp $b} ($id,$entryid);

    if ($id eq $entryid) {

      return ($id,$rest,$pos-$recsize);

    } elsif ($first eq $id) {
	
      if ($end-$start <= 1) {
	return;
      }
      my $end = $mid;
#      print "Moving up $entryid $id\n";
      $self->find_entry($fh,$start,$end,$id,$recsize);

    } elsif ($second eq $id ) {
#	print "Moving down $entryid $id\n";
      if ($end-$start <= 1) {
	return;
      }

      $start = $mid;
      
      $self->find_entry($fh,$start,$end,$id,$recsize);
    }

 }   


=head2 make_index

 Title   : make_index
 Usage   : $obj->make_index($newval)
 Function: 
 Example : 
 Returns : value of make_index
 Args    : newvalue (optional)


=cut

sub make_index {
    my ($self,$dbname,@files) = @_;;
    
    my $rootdir = $self->index_directory;

    if (!defined($rootdir)) {
	$self->throw("No index directory set - can't build indices");
    }
    
    if (! -d $rootdir) {
	$self->throw("Index directory [$rootdir] is not a directory. Cant' build indices");
    }
    if (!(@files)) {
	$self->throw("Must enter an array of filenames to index");
    }
    
    if (!defined($dbname)) {
	$self->throw("Must enter an index name for your files");
    }
    
    my $pwd = `pwd`; chomp($pwd);

    foreach my $file (@files) {
	if ($file !~ /^\//) {
	    $file = $pwd . "/$file";
	}
	if (! -e $file) {
	    $self->throw("Can't index file [$file] as it doesn't exist");
	}
    }
    
    $self->database_name($dbname);
    $self->make_indexdir($rootdir);;
    $self->make_config_file(\@files);
    
    # Finally lets index
    foreach my $file (@files) {
	$self->_index_file($file);
    }

    # And finally write out the indices
    $self->write_primary_index;
    $self->write_secondary_indices;
}

=head2 _index_file

 Title   : _index_file
 Usage   : $obj->_index_file($newval)
 Function: 
 Example : 
 Returns : value of _index_file
 Args    : newvalue (optional)


=cut

sub _index_file {
    my ($self,$file) = @_;

    open(FILE,"<$file") || $self->throw("Can't open file [$file]");

    my $recstart = 0;
    my $fileid = $self->get_fileid_by_filename($file);
    my $found = 0;
    my $id;
    my $count;

    my $primary       = $self->primary_pattern;
    my $start_pattern = $self->start_pattern;

    my $pos = 0;

    my $new_primary_entry;
    
    my $length;
    #my $pos = 0;
    my $fh = \*FILE;

    my $done = -1;

    my @secondary_names = $self->secondary_namespaces;
    my %secondary_id;

    while (<$fh>) {
	if ($_ =~ /$start_pattern/) {
	    if ($done == 0) {
		$id = $new_primary_entry;
		
		my $tmplen = tell($fh) - length($_);

		$length = $tmplen  - $pos;
		
		if (!defined($id)) {
		    $self->throw("No id defined for sequence");
		}
		if (!defined($fileid)) {
		    $self->throw("No fileid defined for file $file");
		}
		if (!defined($pos)) {
		    $self->throw("No position defined for " . $id . "\n");
		}
		if (!defined($length)) {
		    $self->throw("No length defined for " . $id . "\n");
		}
		
		$self->_add_id_position($id,$pos,$fileid,$length,\%secondary_id);

		$pos   = $tmplen;
		
		if ($count%1000 == 0) {
		    print STDERR "Indexed $count ids\n";
		}
	    
		$count++;
	    } else {
		$done = 0;
	    }
	}

	if ($_ =~ /$primary/) {
	    $new_primary_entry = $1;    
	}

	my $secondary_patterns = $self->secondary_patterns;

	foreach my $sec (@secondary_names) {
	    my $pattern = $secondary_patterns->{$sec};

	    if ($_ =~ /$pattern/) {
		$secondary_id{$sec} = $1;
	    }
	}
	
    }

    # Remeber to add in the last one

    $id = $new_primary_entry;
		
    my $tmplen = tell($fh) - length($_);

    $length = $tmplen  - $pos;
    
    if (!defined($id)) {
	$self->throw("No id defined for sequence");
    }
    if (!defined($fileid)) {
	$self->throw("No fileid defined for file $file");
    }
    if (!defined($pos)) {
	$self->throw("No position defined for " . $id . "\n");
    }
    if (!defined($length)) {
	$self->throw("No length defined for " . $id . "\n");
    }
    
    $self->_add_id_position($id,$pos,$fileid,$length,\%secondary_id);
    
    close(FILE);
}

=head2 write_primary_index

 Title   : write_primary_index
 Usage   : $obj->write_primary_index($newval)
 Function: 
 Example : 
 Returns : value of write_primary_index
 Args    : newvalue (optional)


=cut

sub write_primary_index {
    my ($self) = @_;

    my @ids = keys %{$self->{_id}};

    @ids = sort {$a cmp $b} @ids;

    print STDERR "Number of ids = " . scalar(@ids) . "\n";

    open (INDEX,">" . $self->primary_index_file) || $self->throw("Can't open primary index file [" . $self->primary_index_file . "]");

    my $recordlength = $self->{_maxidlength} +
	               $self->{_maxfileidlength} + 
	               $self->{_maxposlength} +
   		       $self->{_maxlengthlength} + 3;
	
    
    print INDEX sprintf("%4d",$recordlength);

    foreach my $id (@ids) {

	if (!defined($self->{_id}{$id}{_fileid})) {
	    $self->throw("No fileid for $id\n");
	}
	if (!defined($self->{_id}{$id}{_pos})) {
	    $self->throw("No position for $id\n");
	}
	if (!defined($self->{_id}{$id}{_length})) {
	    $self->throw("No length for $id");
	}

	my $record =  $id              . "\t" . 
	    $self->{_id}{$id}{_fileid} . "\t" .
	    $self->{_id}{$id}{_pos}    . "\t" .
	    $self->{_id}{$id}{_length};

	print INDEX sprintf("%-${recordlength}s",$record);

    }
    close(INDEX);
}

=head2 write_secondary_indices

 Title   : write_secondary_indices
 Usage   : $obj->write_secondary_indices($newval)
 Function: 
 Example : 
 Returns : value of write_secondary_indices
 Args    : newvalue (optional)


=cut

sub write_secondary_indices {
    my ($self) = @_;

    # These are the different 
    my @names = keys (%{$self->{_secondary_id}});

    
    foreach my $name (@names) {

	my @seconds = keys %{$self->{_secondary_id}{$name}};

	# First we need to loop over to get the longest record.
	my $length = 0;

	foreach my $second (@seconds) {
	    my $tmplen = length($second) + 1;
	    my @prims = keys %{$self->{_secondary_id}{$name}{$second}};

	    foreach my $prim (@prims) {
		my $recordlen = $tmplen + length($prim);
	    
		if ($recordlen > $length) {
		    $length = $recordlen;
		}
	    }
	}

	# Now we can print the index
	
	my $fh = $self->new_secondary_filehandle($name);	

	print $fh sprintf("%4d",$length);
	@seconds = sort @seconds;
	
	foreach my $second (@seconds) {

	    my @prims = keys %{$self->{_secondary_id}{$name}{$second}};
	    my $tmp = $second;

	    foreach my $prim (@prims) {
		my $record = $tmp . "\t" . $prim;
		if (length($record) > $length) {
		    $self->throw("Something has gone horribly wrong - length of record is more than we thought [$length]\n");
		} else {
		    print $fh sprintf("%-${length}s",$record);
		    print $fh sprintf("%-${length}s",$record);
		}
	    }
	}
		
	close($fh);
    }
}

=head2 new_secondary_filehandle

 Title   : new_secondary_filehandle
 Usage   : $obj->new_secondary_filehandle($newval)
 Function: 
 Example : 
 Returns : value of new_secondary_filehandle
 Args    : newvalue (optional)


=cut

sub new_secondary_filehandle {
    my ($self,$name) = @_;

    my $indexdir = $self->index_directory;

    my $secindex = $indexdir . $self->database_name . "/id_$name.index";

    my $fh = new FileHandle(">$secindex");

    return $fh;
}

=head2 open_secondary_index

 Title   : open_secondary_index
 Usage   : $obj->open_secondary_index($newval)
 Function: 
 Example : 
 Returns : value of open_secondary_index
 Args    : newvalue (optional)


=cut

sub open_secondary_index {
    my ($self,$name) = @_;

    if (!defined($self->{_secondary_filehandle}{$name})) {

	my $indexdir = $self->index_directory;
	my $secindex = $indexdir . $self->database_name . "/id_$name.index";
	
	if (! -e $secindex) {
	    $self->throw("Index is not present for namespace [$name]\n");
	}

        my $newfh  = new FileHandle("<$secindex");
	my $reclen = $self->read_header($newfh);

	$self->{_secondary_filehandle} {$name} = $newfh;
	$self->{_secondary_record_size}{$name} = $reclen;
    }

    return $self->{_secondary_filehandle}{$name};

}

=head2 _add_id_position

 Title   : _add_id_position
 Usage   : $obj->_add_id_position($newval)
 Function: 
 Example : 
 Returns : value of _add_id_position
 Args    : newvalue (optional)


=cut

sub _add_id_position {
    my ($self,$id,$pos,$fileid,$length,$secondary_id) = @_;

    if (!defined($id)) {
	$self->throw("No id defined. Can't add id position");
    }
    if (!defined($pos)) {
v	$self->throw("No position defined. Can't add id position");
    }
    if (!defined($fileid)) {
	$self->throw("No fileid defined. Can't add id position");
    }
    if (!defined($length) || $length <= 0) {
	$self->throw("No length defined or <= 0 [$length]. Can't add id position");
    }

    $self->{_id}{$id}{_pos}    = $pos;
    $self->{_id}{$id}{_length} = $length;
    $self->{_id}{$id}{_fileid} = $fileid;
    
    # Now the secondary ids

    foreach my $sec (keys (%$secondary_id)) {
	my $value = $secondary_id->{$sec};

	$self->{_secondary_id}{$sec}{$value}{$id} = 1;
    }

    if (length($id) >= $self->{_maxidlength}) {
	$self->{_maxidlength} = length($id);
    }

    if (length($fileid) >= $self->{_maxfileidlength}) {
	$self->{_maxfileidlength} = length($fileid);
    }

    if (length($pos) >= $self->{_maxposlength}) {
	$self->{_maxposlength} = length($pos);
    }

    if (length($length) >= $self->{_maxlengthlength}) {
	$self->{_maxlengthlength} = length($length);
    }
}

=head2 make_indexdir

 Title   : make_indexdir
 Usage   : $obj->make_indexdir($newval)
 Function: 
 Example : 
 Returns : value of make_indexdir
 Args    : newvalue (optional)


=cut

sub make_indexdir {
    my ($self,$rootdir) = @_;

    if (!defined($rootdir)) {
	$self->throw("Must enter an index directory name for make_indexdir");
    }
    if (! -e $rootdir) {
	$self->throw("Root index directory [$rootdir] doesn't exist");
    }

    if (! -d $rootdir) {
	$self->throw("[$rootdir] exists but is not a directory");
    }

    if ($rootdir !~ /\/$/) {
	$rootdir .= "/";
    }

    my $indexdir = $rootdir . $self->database_name;

    if (! -e $indexdir) {
	mkdir $indexdir,0755;
    } else {
	$self->throw("Index directory " . $indexdir . " already exists. Exiting\n");
    }

}

=head2 make_config_file

 Title   : make_config_file
 Usage   : $obj->make_config_file($newval)
 Function: 
 Example : 
 Returns : value of make_config_file
 Args    : newvalue (optional)

=cut

sub make_config_file {
    my ($self,$files) = @_;
    
    my @files = @$files;

    my $dir = $self->index_directory;

    my $configfile = $dir . $self->database_name . "/" .CONFIG_FILE_NAME;

    open(CON,">$configfile") || $self->throw("Can't create config file [$configfile]");

    # First line must be the type of index - in this case flat

    print CON "index\tflat/1\n";

    # Now the fileids

    my $count = 0;

    foreach my $file (@files) {

	my $size = -s $file;

	print CON "fileid_$count\t$file\t$size\n";

	my $fh = new FileHandle("<$file");
	$self->{_fileid}{$count}   = $fh;
	$self->{_file}  {$count}   = $file;
	$self->{_dbfile}{$file} = $count;
	$self->{_size}{$count}     = $size; 
	
	$count++;
    }

    # Now the namespaces

    print CON "primary_namespace\t" .$self->primary_namespace. "\n";
    
    # Needs fixing for the secondary stuff

    my $second_patterns = $self->secondary_patterns;

    my @second = keys %$second_patterns;

    if ((@second))  {
	print CON "secondary_namespaces";

	foreach my $second (@second) {
	    print CON "\t$second";
	}
        print CON "\n";
    }

    # Now the config format

    if (!defined($self->format)) {
	$self->throw("Format does not exist in module - can't write config file");
    } else {
	print CON "format\t" . $self->format . "\n";
    }


    close(CON);
}

=head2 read_config_file

 Title   : read_config_file
 Usage   : $obj->read_config_file($newval)
 Function: 
 Example : 
 Returns : value of read_config_file
 Args    : newvalue (optional)


=cut

sub read_config_file {
    my ($self) = @_;

    my $dir = $self->index_directory . $self->database_name . "/";;

    if (! -d $dir) {
	$self->throw("No index directory [" . $dir  . "]. Can't read ".  CONFIG_FILE_NAME);
    }
    
    my $configfile = $dir . CONFIG_FILE_NAME;
    
    if (! -e $configfile) {
	$self->throw("No config file [$configfile]. Can't read namespace");
    }
    
    open(CON,"<$configfile") || $self->throw("Can't open configfile [$configfile]");

    # First line must be type

    my $line = <CON>; chomp($line);
    my $version;

    # This is hard coded as we only index flatfiles here
    if ($line =~ /index\tflat\/(\d+)/) {
	$version = $1;
    } else {
	$self->throw("First line not compatible with flat file index.  Should be something like\n\nindex\tflat/1");
    }

    $self->index_type("flat");
    $self->index_version($version);

    while (<CON>) {
	chomp;

	# Look for fileid lines
	if ($_ =~ /^fileid_(\d+)\t(\S+)\t(\d+)/) {
	    my $fileid   = $1;
	    my $filename = $2;
	    my $filesize = $3;
	    
	    if (! -e $filename) {
		$self->throw("File [$filename] does not exist!");
	    }
	    if (-s $filename != $filesize) {
		$self->throw("Flatfile size for $filename differs from what the index thinks it is. Real size [" . (-s $filename) . "] Index thinks it is [" . $filesize  . "]");
	    }
		
	    my $fh = new FileHandle("<$filename");

	    $self->{_fileid}{$fileid}   = $fh;
	    $self->{_file}  {$fileid}   = $filename;
	    $self->{_dbfile}{$filename} = $fileid;
            $self->{_size}  {$fileid}   = $filesize; 

	}

	# Look for namespace lines
	if ($_ =~ /(.*)_namespace.*\t(\S+)/) {
	    if ($1 eq "primary") {
		$self->primary_namespace($2);
	    } elsif ($1 eq "secondary") {
		$self->secondary_namespaces($2);
	    } else {
		$self->throw("Unknown namespace name in config file [$1");
	    }
	}
	
	# Look for format lines

	if ($_ =~ /format\t(\S+)/) {

	    # Check the format here?

	    $self->format($1);
	}
    }
    close(CON);

    # Now check we have all that we need

    my @fileid_keys = keys (%{$self->{_fileid}});
    
    if (!(@fileid_keys)) {
	$self->throw("No flatfile fileid files in config - check the index has been made correctly");
    }

    if (!defined($self->primary_namespace)) {
	$self->throw("No primary namespace exists");
    }

    if (! -e $self->primary_index_file) {
	$self->throw("Primary index file [" . $self->primary_index_file . "] doesn't exist");
    }
}

=head2 get_fileid_by_filename

 Title   : get_fileid_by_filename
 Usage   : $obj->get_fileid_by_filename($newval)
 Function: 
 Example : 
 Returns : value of get_fileid_by_filename
 Args    : newvalue (optional)


=cut

sub get_fileid_by_filename {
    my ($self,$file) = @_;
    
    if (!defined($self->{_dbfile})) {
	$self->throw("No file to fileid mapping present.  Has the fileid file been read?");
    }

    
    return $self->{_dbfile}{$file};
}

=head2 get_filehandle_by_fileid

 Title   : get_filehandle_by_fileid
 Usage   : $obj->get_filehandle_by_fileid($newval)
 Function: 
 Example : 
 Returns : value of get_filehandle_by_fileid
 Args    : newvalue (optional)


=cut

sub get_filehandle_by_fileid {
    my ($self,$fileid) = @_;

    if (!defined($self->{_fileid}{$fileid})) {
	$self->throw("ERROR: undefined fileid in index [$fileid]");
    }
   
    return $self->{_fileid}{$fileid};
}

=head2 primary_index_file

 Title   : primary_index_file
 Usage   : $obj->primary_index_file($newval)
 Function: 
 Example : 
 Returns : value of primary_index_file
 Args    : newvalue (optional)


=cut

sub primary_index_file {
    my ($self) = @_;

    return $self->index_directory . $self->database_name . "/key_" . $self->primary_namespace . ".key";
}

=head2 primary_index_filehandle

 Title   : primary_index_filehandle
 Usage   : $obj->primary_index_filehandle($newval)
 Function: 
 Example : 
 Returns : value of primary_index_filehandle
 Args    : newvalue (optional)


=cut

sub primary_index_filehandle {
    my ($self) = @_;

    if (!defined ($self->{_primary_index_handle})) {
	$self->{_primary_index_handle} = new FileHandle("<" . $self->primary_index_file);
    }
    return $self->{_primary_index_handle};
}

=head2 database_name

 Title   : database_name
 Usage   : $obj->database_name($newval)
 Function: 
 Example : 
 Returns : value of database_name
 Args    : newvalue (optional)


=cut


sub database_name {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_database_name} = $arg;
    }
    return $self->{_database_name};

}

=head2 format

 Title   : format
 Usage   : $obj->format($newval)
 Function: 
 Example : 
 Returns : value of format
 Args    : newvalue (optional)


=cut

sub format{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'format'} = $value;
    }
    return $obj->{'format'};

}

=head2 index_directory

 Title   : index_directory
 Usage   : $obj->index_directory($newval)
 Function: 
 Example : 
 Returns : value of index_directory
 Args    : newvalue (optional)


=cut

sub index_directory {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	if ($arg !~ /\/$/) {
	    $arg .= "/";
	}
	$self->{_index_directory} = $arg;
    }
    return $self->{_index_directory};

}

=head2 record_size

 Title   : record_size
 Usage   : $obj->record_size($newval)
 Function: 
 Example : 
 Returns : value of record_size
 Args    : newvalue (optional)


=cut

sub record_size {
    my ($self,$arg) = @_;

    if (defined($arg)) {
      $self->{_record_size} = $arg;
    }
    return $self->{_record_size};
}

=head2 primary_namespace

 Title   : primary_namespace
 Usage   : $obj->primary_namespace($newval)
 Function: 
 Example : 
 Returns : value of primary_namespace
 Args    : newvalue (optional)

=cut

sub primary_namespace {
  my ($self,$arg) =  @_;

  if (defined($arg)) {
    $self->{_primary_namespace} =  $arg;
  }
  return $self->{_primary_namespace};
}

=head2 index_type

 Title   : index_type
 Usage   : $obj->index_type($newval)
 Function: 
 Example : 
 Returns : value of index_type
 Args    : newvalue (optional)


=cut

sub index_type {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_index_type} = $arg;
    }
    return $self->{_index_type};
}

=head2 index_version

 Title   : index_version
 Usage   : $obj->index_version($newval)
 Function: 
 Example : 
 Returns : value of index_version
 Args    : newvalue (optional)


=cut

sub index_version {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_index_version} = $arg;
    }
    return $self->{_index_version};
}

=head2 primary_pattern

 Title   : primary_pattern
 Usage   : $obj->primary_pattern($newval)
 Function: 
 Example : 
 Returns : value of primary_pattern
 Args    : newvalue (optional)


=cut

sub primary_pattern{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'primary_pattern'} = $value;
    }

    return $obj->{'primary_pattern'};

}
=head2 start_pattern

 Title   : start_pattern
 Usage   : $obj->start_pattern($newval)
 Function: 
 Example : 
 Returns : value of start_pattern
 Args    : newvalue (optional)


=cut

sub start_pattern{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'start_pattern'} = $value;
    }
    return $obj->{'start_pattern'};

}

=head2 secondary_patterns

 Title   : secondary_patterns
 Usage   : $obj->secondary_patterns($newval)
 Function: 
 Example : 
 Returns : value of secondary_patterns
 Args    : newvalue (optional)


=cut

sub secondary_patterns{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'secondary_patterns'} = $value;

      my @names = keys %$value;

      foreach my $name (@names) {
	  $obj->secondary_namespaces($name);
      }
    }
    return $obj->{'secondary_patterns'};

}

=head2 secondary_namespaces

 Title   : secondary_namespaces
 Usage   : $obj->secondary_namespaces($newval)
 Function: 
 Example : 
 Returns : value of secondary_namespaces
 Args    : newvalue (optional)


=cut

sub secondary_namespaces{
   my ($obj,$value) = @_;

   if (!defined($obj->{secondary_namespaces})) {
       $obj->{secondary_namespaces} = [];
   }
   if( defined $value) {
       push(@{$obj->{'secondary_namespaces'}},$value);
    }
   return @{$obj->{'secondary_namespaces'}};

}



## These are indexing routines to index commonly used format - fasta
## swissprot and embl

sub new_SWISSPROT_index {
    my ($self,$index_dir,$dbname,@files) = @_;
    
    my %secondary_patterns;
    
    my $start_pattern = "^ID   (\\S+)";
    my $primary_pattern = "^AC   (\\S+)\\;";
    
    $secondary_patterns{"ID"} = $start_pattern;

    my $index =  new Bio::DB::Flat::OBDAIndex(-index_dir          => $index_dir,
					      -format             => 'swiss',
					      -primary_pattern    => $primary_pattern,
					      -primary_namespace  => "ACC",
					      -start_pattern      => $start_pattern,
					      -secondary_patterns => \%secondary_patterns);
    
    $index->make_index($dbname,@files);
}

sub new_EMBL_index {
   my ($self,$index_dir,$dbname,@files) = @_;
   
   my %secondary_patterns;

   my $start_pattern = "^ID   (\\S+)";
   my $primary_pattern = "^AC   (\\S+)\\;";
   my $primary_namespace = "ACC";

   $secondary_patterns{"ID"} = $start_pattern;

   my $index = new Bio::DB::Flat::OBDAIndex(-index_dir          => $index_dir,
					    -format             => 'embl',
					    -primary_pattern    => $primary_pattern,
					    -primary_namespace  => "ACC",
					    -start_pattern      => $start_pattern,
					    -secondary_patterns => \%secondary_patterns);
   
    $index->make_index($dbname,@files);

   return $index;
}

sub new_FASTA_index {
   my ($self,$index_dir,$dbname,@files) =  @_;

   my %secondary_patterns;

   my $start_pattern = "^>";
   my $primary_pattern = "^>(\\S+)";
   my $primary_namespace = "ACC"; 

   $secondary_patterns{"ID"} = "^>\\S+ +(\\S+)";

   my $index =  new Bio::DB::Flat::OBDAIndex(-index_dir          => $index_dir,
					     -format             => 'fasta',
					     -primary_pattern    => $primary_pattern,
					     -primary_namespace  => "ACC",
					     -start_pattern      => $start_pattern,
					     -secondary_patterns => \%secondary_patterns);
   
   $index->make_index($dbname,@files);

   return $index;

}



1;

	

    


























