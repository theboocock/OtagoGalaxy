package Bio::EnsEMBL::ExternalData::Glovar::Haplotype;

=head1 NAME

Bio::EnsEMBL::ExternalData::Glovar::Haplotype -
Object representing a Glovar haplotype

=head1 SYNOPSIS

my $hap = new Bio::EnsEMBL::ExternalData::Glovar::Haplotype(-start   => 100,
                                                            -end     => 300,
                                                            -strand  => 1,
                                                            -slice   => $slice
                                                        );
$hap->population('Caucasian');
$hap->num_snps(10);
$hap->add_tagSNP(50000, 50000);

=head1 DESCRIPTION

This object represents a Glovar haplotype. In addition to the usual attributes
of a Bio::EnsEMBL::Feature, it holds information like sample population, number
of tagSNPs on the haplotype and start/end positions of the tagSNPs.

=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 AUTHOR

Patrick Meidl <pm2@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::Feature;
use Bio::EnsEMBL::Utils::Exception qw(throw);
@ISA = qw(Bio::EnsEMBL::Feature);

=head2 new_fast

  Arg[1]      : Hashref - initial values for the object
  Example     : 
  Description : creates a new Bio::EnsEMBL::ExternalData::Glovar::Haplotype
                very quickly by blessing a passed hashref into the object. To
                be used by the drawingcode for fast object creation
  Return type : Bio::EnsEMBL::ExternalData::Glovar::Haplotype
  Exceptions  : none
  Caller      : drawingcode

=cut

sub new_fast {
    my $class = shift;
    my $hashref = shift;
    return bless $hashref, $class;
}

=head2 display_id

  Arg[1]      : (optional) String - ID to set
  Example     : $self->display_id('1234');
  Description : getter/setter for Haplotype display ID
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub display_id {
    my $self = shift;
    $self->{'display_id'} = shift if (@_);
    return $self->{'display_id'};
}

=head2 population

  Arg[1]      : (optional) String - population to set
  Example     : $self->population('Caucasian');
  Description : getter/setter for population
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub population {
    my $self = shift;
    $self->{'population'} = shift if (@_);
    return $self->{'population'};
}

=head2 num_snps

  Arg[1]      : (optional) String - number of tag SNPs on haplotype to set
  Example     : $self->num_snps(7);
  Description : getter/setter for the number of tag SNPs on the haplotype
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub num_snps {
    my $self = shift;
    $self->{'num_snps'} = shift if (@_);
    return $self->{'num_snps'};
}

=head2 add_tagSNP

  Arg[1]      : String $start - SNP start in chromosomal coordinates
  Arg[2]      : String $end - SNP end in chromosomal coordinates
  Example     : $haplotype->add_tagSNP(123, 123);
  Description : adds tag SNPs to haplotype
  Return type : none
  Exceptions  : thrown if no start/end are provided or start > end
  Caller      : general

=cut

sub add_tagSNP {
    my ($self, $start, $end) = @_;
    throw("Need tagSNP start and end as arguments") unless ($start and $end);
    throw("Start must be < end") if ($start > $end);
    push @{ $self->{'tag_snps'} }, { start => $start, end => $end };
}

=head2 get_all_tagSNPs

  Example     : my @tags = $haplotype->get_all_tagSNPs;
                foreach my $tag (@tags) {
                    print "tag start: " . $tag->start . "\n";
                    print "tag end: " . $tag->end . "\n";
                }
  Description : gets all tag SNPs on the haplotype
  Return type : List of hashrefs (keys: start, end)
  Exceptions  : none
  Caller      : general

=cut

sub get_all_tagSNPs {
    my $self = shift;
    return @{ $self->{'tag_snps'} || [] };
}

1;

