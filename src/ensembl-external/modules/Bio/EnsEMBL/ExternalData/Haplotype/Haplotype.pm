# 
# BioPerl module for Bio::EnsEMBL::ExternalData::Haplotype::Haplotype
# 
# Cared for by Tony Cox <avc@sanger.ac.uk>
#
# Copyright EnsEMBL
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

HaplotypeAdaptor - DESCRIPTION of Object

  This object represents a database of haplotypes.

=head1 SYNOPSIS

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::Haplotype::HaplotypeAdaptor;
use Bio::EnsEMBL::ExternalData::Haplotype::Haplotype;

$hapdb = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
                                             -user   => 'ensro',
                                             -dbname => 'haplotype_5_28',
                                             -host   => 'ecs3d',
                                             -driver => 'mysql',
                                            );
my $hap_adtor = Bio::EnsEMBL::ExternalData::Haplotype::HaplotypeAdaptor->new($hapdb);

$hap  = $hap_adtor->get_Haplotype_by_id('B10045');  # Haplotype id

### You can add the HaplotypeAdaptor as an 'external adaptor' to the 'main'
### Ensembl database object, then use it as:

$ensdb = Bio::EnsEMBL::DBSQL::DBAdaptor->new( ... );

$ensdb->add_ExternalAdaptor('haplotype', $hap_adtor);

# then later on, elsewhere: 
$hap_adtor = $ensdb->get_ExternalAdaptor('haplotype');
# also available:
$ensdb->list_ExternalAdaptors();
$ensdb->remove_ExternalAdaptor('haplotype');

=head1 DESCRIPTION

This module is an entry point into a database of haplotypes,

The objects can only be read from the database, not written. (They are
loaded ussing a separate perl script).

For more info, see Haplotype.pm

=head1 CONTACT

 Tony Cox <Lavc@sanger.ac.uk>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...;

package Bio::EnsEMBL::ExternalData::Haplotype::Haplotype;
use vars qw(@ISA);
use strict;

# Object preamble - inheriets from Bio::Root::Object

use Bio::Root::Object;


@ISA = qw(Bio::Root::Object);

=head2 new

 Title   : new
 Usage   : not intended for general use.
 Function:
 Example :
 Returns : a haplotype - caller has to fill using methods
 Args    :
         
=cut

sub new {

   my ($class, $adaptor) = @_;
   my $self = {'_adaptor' => $adaptor};
   bless $self,$class;
   $self;
}

=head2 id

 Title   : id
 Usage   : 
 Function: get/set the display id of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub id {
    my ($self,$value) = @_;
    if( defined $value) {
		$self->{'id'} = $value;
    }
    return $self->{'id'};
}

=head2 chr_name

 Title   : chr_name
 Usage   : 
 Function: get/set the chr_name of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub chr_name {
    my ($self,$value) = @_;
    if( defined $value) {
		$self->{'chr_name'} = $value;
    }
    return $self->{'chr_name'};
}

=head2 contig_id

 Title   : contig_id
 Usage   : 
 Function: get/set the contig id of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub contig_id {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'contig_id'} = $value;
    }
    return $self->{'contig_id'};
}

=head2 start

 Title   : start
 Usage   : 
 Function: get/set the global (chromosomal) start of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub start {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'start'} = $value;
    }
    return $self->{'start'};
}


=head2 end

 Title   : end
 Usage   : 
 Function: get/set the global (chromosomal) end of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub end {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'end'} = $value;
    }
    return $self->{'end'};
}


=head2 local_start

 Title   : local_start
 Usage   : 
 Function: get/set the local (contig) start of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub local_start {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'local_start'} = $value;
    }
    unless ($self->{'local_start'}){
        my $id = $self->id();
        my $q = qq(
        	select first_reference_position from block 
        	where block_id = "$id"
		);
        my $sth = $self->adaptor->prepare($q);
        $sth->execute();
        ($self->{'local_start'}) = $sth->fetchrow_array()
    }
    return $self->{'local_start'};
}


=head2 local_end

 Title   : local_end
 Usage   : 
 Function: get/set the local (contig) end of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub local_end {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'local_end'} = $value;
    }
    unless ($self->{'local_end'}){
        my $id = $self->id();
        my $q = qq(
        	select last_reference_position from block 
        	where block_id = "$id"
		);
        my $sth = $self->adaptor->prepare($q);
        $sth->execute();
        ($self->{'local_end'}) = $sth->fetchrow_array()
    }
    return $self->{'local_end'};
}


=head2 snp_req

 Title   : snp_req
 Usage   : 
 Function: get/set the number of SNPs required to unambiguously this Haplotype pattern
 Example :
 Returns : 
 Args    : 
=cut

sub snp_req {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'snp_req'} = $value;
    }
    return $self->{'snp_req'};
}


=head2 snp_info

 Title   : snp_info
 Usage   : 
 Function: get snp_info for names SNP  of the Haplotype
 Example :
 Returns : ref to hash of snp info
 Args    : read only
=cut

sub snp_info {
    my ($self,$value) = @_;
    unless ($self->{'snp_info'}->{$value}){
        my $q = qq(
            select 
                 position,ref_base,alt_base,ref_calls,mut_calls
            from 
                polymorphism
            where 
                polymorphism_id = "$value"
            );
        my $sth = $self->adaptor->prepare($q);
        $sth->execute();
        $self->{'snp_info'}->{$value} = $sth->fetchrow_hashref()
    }
    return $self->{'snp_info'}->{$value};
}


=head2 snps

 Title   : snps
 Usage   : 
 Function: get/set the IDs of SNPs in this Haplotype pattern
 Example :
 Returns : ref to list of SNP IDs
 Args    : ref to list of SNP IDs
=cut

sub snps {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'snps'} = $value;
    }
    return $self->{'snps'};
}


=head2 patterns

 Title   : pattern
 Usage   : 
 Function: get/set the sorted list of patterns for this Haplotype consensus
 Example :
 Returns : 
 Args    :ref to a list of pattern objects (they will be sorted on order of size)
=cut

sub patterns {

    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'patterns'} = $value;
    }
    my @pats = reverse sort { $a->count <=> $b->count } @{$self->{'patterns'}};
    return(\@pats);
}

=head2 adaptor

 Title   : _adaptor
 Usage   : $adaptor = $hap->adaptor
 Function: find this objects\'s adaptor object (set by HaplotypeAdaptor)
 Example :
 Returns : 
 Args    : 
 
=cut

sub adaptor {

  my ($self)= shift;
  return $self->{'_adaptor'};
}

=head2 samples_count

 Title   : samples_count
 Usage   : 
 Function: store number of classified samples
 Example :
 Returns : 
 Args    : 
=cut

sub samples_count {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'samples_count'} = $value;
    }
    return $self->{'samples_count'} ||= 0;
}

=head2 unclassified_samples_count

 Title   : unclassified_samples_count
 Usage   : 
 Function: store number of unclassified samples
 Example :
 Returns : 
 Args    : ref to a hash of sample=>patterns
=cut

sub unclassified_samples_count {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'unclassified_samples_count'} = $value;
    }
    return $self->{'unclassified_samples_count'} ||= 0;
}

=head2 total_samples

 Title   : total_samples
 Usage   : 
 Function: store total_samples
 Example :
 Returns : 
 Args    : 
=cut

sub total_samples {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'total_samples'} = $value;
    }
    return $self->{'total_samples'} ||= 0;
}

sub fetchSNPs {
    my ($self) = @_;
    return $self->adaptor->fetchSNPs( $self->id );    
}
1;
