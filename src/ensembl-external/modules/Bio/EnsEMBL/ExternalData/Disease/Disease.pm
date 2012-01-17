#
# BioPerl module for Bio::EnsEMBL::ExternalData::Disease::Disease
#
# Written by Arek Kasprzyk <arek@ebi.ac.uk>
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::Disease::Disease

=head1 SYNOPSIS

# Instantiate an empty object.
$disease=new Bio::EnsEMBL::ExternalData::Disease::Disease;
$disease->name('...');
$disease->add_Location($location); # add DiseaseLocation object.

# Fetch objects by DBHandler.
# See DBHandler docs.

# Usage
my @locations=$disease->each_Location;

=head1 DESCRIPTION

This object represents a disease, a container for DiseaseLocation objects

=head1 AUTHOR - Arek Kasprzyk

Email arek@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::ExternalData::Disease::Disease; 

use strict;
use Bio::EnsEMBL::Root;
use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::Root);

sub new 
{
    my($class,@locations) = @_;
    my $self = bless {}, $class;
         
    $self->{'_disease_location_array'} = [];
    
    foreach my $location (@locations){$self->add_location($location);}

    return $self; 
}

=head2 name

 Title   : name
 Usage   :
 Function: Get/set for disease brief. Refer to NCBI OMIM records
 Example :
 Returns : 
 Args    :


=cut

sub name
{
    my ($self,$value)=@_;

  if( defined $value) {$self->{'name'} = $value;}  
  return $self->{'name'};
}


=head2 add_Location

 Title   : add_Location
 Usage   :
 Function: attach a DiseaseLocation object.
 Example :
 Returns : 
 Args    :


=cut



sub add_Location 
{                          
 my ($self,$location)=@_;

 if( ! $location->isa("Bio::EnsEMBL::ExternalData::Disease::DiseaseLocation") ) {
       $self->throw("$location is not a Bio::EnsEMBL::Disease::DiseaseLocation!");
   }

   push(@{$self->{'_disease_location_array'}},$location);

}



=head2 each_Location

 Title   : each_Location
 Usage   :
 Function:
 Example :
 Returns : An array of DiseaseLocation objects. 
 Args    : [None]


=cut


sub each_Location{
   my ($self) = @_;

   return @{$self->{'_disease_location_array'}};
}


1;
