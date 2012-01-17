# 
# BioPerl module for Bio::EnsEMBL::ExternalData::Haplotype::Pattern
# 
# Cared for by Tony Cox <avc@sanger.ac.uk>
#
# Copyright EnsEMBL
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Pattern - DESCRIPTION of Object

  This object represents a database of haplotype patterns.

=head1 SYNOPSIS

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::Haplotype::HaplotypeAdaptor;
use Bio::EnsEMBL::ExternalData::Haplotype::Haplotype;
use Bio::EnsEMBL::ExternalData::Haplotype::Pattern;

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

package Bio::EnsEMBL::ExternalData::Haplotype::Pattern;
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
 Returns : a haplotype pattern - caller may also fill using methods
 Args    :
         
=cut

sub new {

    my ($class, $adaptor, $pattern_id, $count, $pattern, $pattern_frequency) = @_;
    my $self = {};
    bless $self,$class;
    
    $self->{'_adaptor'}          = $adaptor;
    $self->{'pattern_id'}        = $pattern_id;
    $self->{'count'}             = $count;
    $self->{'pattern'}           = uc($pattern);
    $self->{'pattern_frequency'} = $pattern_frequency;

    return($self);
}

=head2 id

 Title   : id
 Usage   : 
 Function: get/set the display id of the pattern
 Example :
 Returns : 
 Args    : 
=cut

sub id {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->pattern_id($value);
    }
    return $self->pattern_id();
}


=head2 pattern_id

 Title   : pattern_id
 Usage   : 
 Function: get/set the display id of the pattern
 Example :
 Returns : 
 Args    : 
=cut

sub pattern_id {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'pattern_id'} = $value;
    }
    return $self->{'pattern_id'};
}


=head2 block_id

 Title   : block_id
 Usage   : 
 Function: get/set the block id of the Haplotype
 Example :
 Returns : 
 Args    : 
=cut

sub block_id {
    my ($self,$value) = @_;
    if( defined $value) {
	    $self->{'block_id'} = $value;
    }
    return $self->{'block_id'};
}

=head2 count

 Title   : count
 Usage   : 
 Function: get/set the count for the pattern
         : this is number of chromosomes that were observed to be consistent
         : with this pattern
 Example :
 Returns : 
 Args    : 
=cut

sub count {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'count'} = $value;
    }
    return $self->{'count'};
}

=head2 pattern_length

 Title   : pattern_length
 Usage   : read only
 Function: get the length for the pattern
 Example :
 Returns : 
 Args    : 
=cut

sub pattern_length {
    my ($self) = @_;
    return (length($self->{'pattern'}));
}


=head2 pattern

 Title   : pattern
 Usage   : 
 Function: get/set the consensus pattern of bases for this pattern
 Example :
 Returns : 
 Args    : 
=cut

sub pattern {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'pattern'} = $value;
    }
    return $self->{'pattern'};
}

=head2 pattern_frequency

 Title   : pattern_frequency
 Usage   :
 Function: get/set the consensus pattern frequency for this pattern
 Example :
 Returns :
 Args    :
=cut

sub pattern_frequency {
    my ($self,$value) = @_;
    if( defined $value) {
        $self->{'pattern_frequency'} = $value;
    }
    return $self->{'pattern_frequency'};
}


=head2 samples

 Title   : samples
 Usage   : 
 Function: store a ref to a hash of sample data
 Example :
 Returns : 
 Args    : ref to a hash of sample=>patterns
=cut

sub samples {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'samples'} = $value;
    }
    return $self->{'samples'};
}

=head2 unclassified_samples

 Title   : unclassified_samples
 Usage   : 
 Function: store a ref to a hash of unclassified sample data
 Example :
 Returns : 
 Args    : 
=cut

sub unclassified_samples {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'unclassified_samples'} = $value;
    }
    return $self->{'unclassified_samples'};
}


=head2 ref_base

 Title   : ref_base
 Usage   : 
 Function: get/set the reference sequence base for the pattern
 Example :
 Returns : 
 Args    : 
=cut

sub ref_base {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'ref_base'} = $value;
    }
    return $self->{'ref_base'};
}

=head2 alt_base

 Title   : alt_base
 Usage   : 
 Function: get/set the alternative sequence base for the pattern
 Example :
 Returns : 
 Args    : 
=cut

sub alt_base {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'alt_base'} = $value;
    }
    return $self->{'alt_base'};
}


=head2 ref_calls

 Title   : ref_calls
 Usage   : 
 Function: get/set the no calls of reference sequence base for the pattern
 Example :
 Returns : 
 Args    : 
=cut

sub ref_calls {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'ref_calls'} = $value;
    }
    return $self->{'ref_calls'};
}

=head2 alt_calls

 Title   : alt_base
 Usage   : 
 Function: get/set the no calls of the alternative sequence base for the pattern
 Example :
 Returns : 
 Args    : 
=cut

sub alt_calls {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'alt_calls'} = $value;
    }
    return $self->{'alt_calls'};
}

1;
