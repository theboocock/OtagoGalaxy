=head1 NAME

Bio::EnsEMBL::ExternalData::Glovar::BaseComposition -
This object represents the base composition as provided by Glovar

=head1 SYNOPSIS

  my $base_comp = new Bio::EnsEMBL::ExternalData::Glovar::BaseComposition;
  $base_comp->postition('1000');
  $base_comp->genomic_base('A');

=head1 DESCRIPTION

This module holds data describing the base composition for each base in the
genome that has been covered by the Glovar project.

=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 AUTHOR

Jody Clements <jc3@sanger.ac.uk>
Patrick Meidl <pm2@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

package Bio::EnsEMBL::ExternalData::Glovar::BaseComposition;

use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::SimpleFeature;
@ISA = qw(Bio::EnsEMBL::SimpleFeature);

=head2 new

  Arg[1]      : none
  Example     : see SYNOPSIS
  Description : constructor method for a
                Bio::EnsEMBL::ExternalData::Glovar::BaseComposition object
  Return type : Bio::EnsEMBL::ExternalData::Glovar::BaseComposition
  Exceptions  : none
  Caller      : general

=cut

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {
        'position'     => 0,
        'genomic_base' => 'undef',
        'alleles'      => {},
        'ethnicity'    => {},
        '_gsf_strand'  => 1,
        @_,
    };
    bless $self, $class;
    return $self;
}

=head2 new_fast

  Arg[1]      : hashref - initial object attributes
  Example     : 
    my $base_comp = new Bio::EnsEMBL::ExternalData::Glovar::BaseComposition({
                        'position'     => 1,
                        'genomic_base' => 'A',
                        'alleles'      => {
                                            T => 20,
                                            G => 10,
                                            A => 0,
                                            C => 2
                        },
                        'ethnicity'    => {
                                            Asian => 9,
                                            Caucasian => 15,
                        },
                        '_gsf_strand'  => 1,
    });
  Description : fast constructor method for a
                Bio::EnsEMBL::ExternalData::Glovar::BaseComposition object.
                Blesses the hashref supplied into your object
  Return type : Bio::EnsEMBL::ExternalData::Glovar::BaseComposition
  Exceptions  : none
  Caller      : general

=cut

sub new_fast {
    my $class = shift;
    my $hashref = shift;
    return bless $hashref, $class;
}

=head2 position

  Arg[1]      : (optional) Int - genomic position
  Example     : $base_comp->position('1000');
  Description : getter/setter for genomic position of BaseComposition object
  Return type : Int - genomic position
  Exceptions  : none
  Caller      : general

=cut

sub position {
    my ($self,$arg) = @_;
    if(defined $arg){
        $self->{'position'} = $arg;
    }
    return $self->{'position'};
}

=head2 start

  Arg[1]      : (optional) Int - genomic start position
  Example     : $base_comp->start('1000');
  Description : getter/setter for genomic start position of BaseComposition
                object
  Return type : Int - genomic start position
  Exceptions  : none
  Caller      : general

=cut

sub start {
    my ($self,$arg) = @_;
    $self->position($arg) if(defined $arg);
    return $self->position();
}

=head2 end

  Arg[1]      : (optional) Int - genomic end position
  Example     : $base_comp->position('1000');
  Description : getter/setter for genomic end position of BaseComposition
                object. Identical to start position (since lenght of feature is
                always 1)
  Return type : Int - genomic end position
  Exceptions  : none
  Caller      : general

=cut

sub end {
    my ($self,$arg) = @_;
    $self->position($arg) if(defined $arg);
    return $self->position();
}

=head2 genomic_base

  Arg[1]      : (optional) String - genomic base
  Example     : $base_comp->genomic_base('A');
  Description : getter/setter for genomic base of the variation (allele in
                reference sequence)
  Return type : String - genomic base
  Exceptions  : none
  Caller      : general

=cut

sub genomic_base {
    my ($self, $arg) = @_;
    $self->{'genomic_base'} = $arg if (defined $arg);
    return $self->{'genomic_base'};
}

=head2 alleles

  Arg[1]      : (optional) hashref - alleles and their frequencies
  Example     : $base_comp->alleles({'A'=>3,'C'=>1,'G'=>0,'T'=>10});
  Description : getter/setter for allele distribution
  Return type : hashref - alleles and their freqencies
  Exceptions  : none
  Caller      : general

=cut

sub alleles {
    my($self,$arg) = @_;
    $self->{'alleles'} = $arg if(defined $arg);
    return $self->{'alleles'};
}

=head2 ethnicity

  Arg[1]      : (optional) hashref - ethnicities and their read frequencies
  Example     : $base_comp->ethnicity({'Asian'=>2,'Caucasian'=>5});
  Description : getter/setter for ethnicity of the reads the variation was
                observed
  Return type : hashref - ethnicities and their frequencies
  Exceptions  : none
  Caller      : general

=cut

sub ethnicity {
    my ($self, $arg) = @_;
    $self->{'ethnicity'} = $arg if (defined $arg);
    return $self->{'ethnicity'};
}

1;








