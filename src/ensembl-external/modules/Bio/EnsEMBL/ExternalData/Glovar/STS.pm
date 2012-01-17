package Bio::EnsEMBL::ExternalData::Glovar::STS;

=head1 NAME

Bio::EnsEMBL::ExternalData::Glovar::STS -
Object representing a Glovar STS

=head1 SYNOPSIS

my $sts = new Bio::EnsEMBL::ExternalData::Glovar::STS(-start   => 100,
                                                      -end     => 300,
                                                      -strand  => 1,
                                                      -slice   => $slice
                                                     );
$sts->sense_length(21);
$sts->antisense_length(20);
$sts->pass_status('PCR_pass');

=head1 DESCRIPTION

This object represents a Glovar STS. In addition to the usual attributes of
a Bio::EnsEMBL::Feature, it holds information like sense and antisense primer
length and test pass status.

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
@ISA = qw(Bio::EnsEMBL::Feature);

=head2 new_fast

  Arg[1]      : Hashref - initial values for the object
  Example     : 
  Description : creates a new Bio::EnsEMBL::ExternalData::Glovar::STS very
                quickly by blessing a passed hashref into the object. To be
                used by the drawingcode for fast object creation
  Return type : Bio::EnsEMBL::ExternalData::Glovar::STS
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
  Example     : $self->display_id('stsG2345');
  Description : getter/setter for STS display ID
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub display_id {
    my $self = shift;
    $self->{'display_id'} = shift if (@_);
    return $self->{'display_id'};
}

=head2 sense_length

  Arg[1]      : (optional) String - primer length to set
  Example     : $self->sense_length(20);
  Description : getter/setter for sense primer length
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub sense_length {
    my $self = shift;
    $self->{'sense_length'} = shift if (@_);
    return $self->{'sense_length'};
}

=head2 antisense_length

  Arg[1]      : (optional) String - length to set
  Example     : $self->antisense_length(25);
  Description : getter/setter for antisense primer length
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub antisense_length {
    my $self = shift;
    $self->{'antisense_length'} = shift if (@_);
    return $self->{'antisense_length'};
}

=head2 pass_status

  Arg[1]      : (optional) String - pass status to set
  Example     : $self->pass_status('pass');
  Description : getter/setter for pass status
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub pass_status {
    my $self = shift;
    $self->{'pass_status'} = shift if (@_);
    return $self->{'pass_status'};
}

=head2 assay_type

  Arg[1]      : (optional) String - assay type to set
  Example     : $self->assay_type('ExoSeq');
  Description : getter/setter for assay type
  Return type : String
  Exceptions  : none
  Caller      : general

=cut

sub assay_type {
    my $self = shift;
    $self->{'assay_type'} = shift if (@_);
    return $self->{'assay_type'};
}

1;
