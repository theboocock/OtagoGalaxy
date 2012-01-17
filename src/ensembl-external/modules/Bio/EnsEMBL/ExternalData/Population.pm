package Bio::EnsEMBL::ExternalData::Population;

=head1 NAME

Bio::EnsEMBL::ExternalData::Population - create Population object for subSNP frequencies

=head1 SYNOPSIS

 my $snp_renderer = $snp_data->renderer;
 $snp_renderer->outputFrequencyTable;

=head1 DESCRIPTION

 Container object attached to SNPs which holds allele frequency objects per population for a subSNP.


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

=head2 name

  Arg [1]    : string population name
  Example    : none
  Description: get/set for population name 
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub name {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'name'} = $value;
  }
  return $self->{'name'};
}

=head2 region

  Arg [1]    : string region
  Example    : none
  Description: get/set for the geographical region of the population
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub region {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'region'} = $value;
  }
  return $self->{'region'};
}

=head2 pop_id

  Arg [1]    : integer for population ID
  Example    : none
  Description: get/set population ID
  Returntype : int
  Exceptions : none
  Caller     : general

=cut

sub pop_id {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'pop_id'} = $value;
  }
  return $self->{'pop_id'};
}

=head2 sample_size

  Arg [1]    : integer sample size
  Example    : none
  Description: get/set for sample size
  Returntype : integer
  Exceptions : none
  Caller     : general

=cut

sub sample_size {
  my ($self, $value) =@_;
  if ( defined $value){
    $self->{'sample_size'} = $value;
  }
  return $self->{'sample_size'};
}

=head2 add_frequency

  Arg 1      : Bio::EnsEMBL::ExternalData::Frequency object
  Example    : none
  Description: add a frequency object
  Returntype : none
  Exceptions : none
  Caller     : general

=cut


sub add_frequency{
   my ($self,$com) = @_;
   push(@{$self->{'_frequency'}},$com);
}

=head2 each_frequency

  Arg        : none
  Example    : none
  Description: return a frequency object
  Returntype : array of Bio::EnsEMBL::ExternalData::Frequency objects
  Exceptions : none
  Caller     : general

=cut

sub each_frequency{
   my ($self) = @_;
   return @{$self->{'_frequency'}} if defined $self->{'_frequency'};
}


1;
