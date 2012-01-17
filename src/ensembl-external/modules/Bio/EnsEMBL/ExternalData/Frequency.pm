package Bio::EnsEMBL::ExternalData::Frequency;

=head1 NAME

Bio::EnsEMBL::ExternalData::Frequency- create Frequency object for subSNP population

=head1 SYNOPSIS

    my $snp_renderer = $snp_data->renderer;
    $snp_renderer->outputFrequencyTable;

=head1 DESCRIPTION

 Container object attached to SNPs population objects which holds allele frequencies for a subSNP.


=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 CONTACT

Fiona Cunningham <fc1@sanger.ac.uk>

=cut

use strict;
use warnings;
no warnings "uninitialized";

sub new {
    my $class = shift;
    my $self = {};

    # rebless into own class
    bless $self, $class;
    return $self;
}

=head2 allele

  Arg [1]    : string allele or 'otherallele' e.g. indel
  Example    : none
  Description: get/set for allele
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub allele {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'allele'} = $value;
  }
  return $self->{'allele'};
}

=head2 frequency

  Arg [1]    : integer frequency
  Example    : none
  Description: get/set for the allele frequency
  Returntype : integer
  Exceptions : none
  Caller     : general

=cut

sub frequency {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'frequency'} = $value;
  }
  return $self->{'frequency'};
}

=head2 count

  Arg [1]    : integer count
  Example    : none
  Description: get/set for number of people sampled
  Returntype : integer
  Exceptions : none
  Caller     : general

=cut

sub count {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'count'} = $value;
  }
  return $self->{'count'};
}

=head2 ssid

  Arg [1]    : integer ssid
  Example    : none
  Description: get/set the ssid
  Returntype : integer
  Exceptions : none
  Caller     : general

=cut

sub ssid {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'ssid'} = $value;
  }
  return $self->{'ssid'};
}

=head2 batch_id

  Arg [1]    : integer batch ID
  Example    : none
  Description: get/set the batch id
  Returntype : integer
  Exceptions : none
  Caller     : general

=cut

sub batch_id {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'batch_id'} = $value;
  }
  return $self->{'batch_id'};
}

1;
