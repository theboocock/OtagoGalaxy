#
# BioPerl module for Bio::EnsEMBL::ExternalData::Disease::DiseaseLocation
#
# Written by Arek Kasprzyk <arek@ebi.ac.uk>
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::Disease::Disease

=head1 SYNOPSIS

 my $location=new Bio::EnsEMBL::ExternalData::Disease::DiseaseLocation(
							    -db_id=>$rowhash->{'omim_id'},
							    -cyto_start=>$rowhash->{'start_cyto'},
							    -cyto_end=>$rowhash->{'end_cyto'},
							    -external_gene=>$rowhash->{'gene_symbol'},
							    -chromosome=>$rowhash->{'chromosome'});

=head1 DESCRIPTION

This object holds info about genomic location of a disease phenotype

=head1 AUTHOR - Arek Kasprzyk

Email arek@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


package Bio::EnsEMBL::ExternalData::Disease::DiseaseLocation; 


use strict;
use Bio::EnsEMBL::Root;
use vars qw(@ISA);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
@ISA = qw(Bio::EnsEMBL::Root);


=head2 new

  Title     : new
  Usage     : see DBHandler's fetch methods

=cut 

sub new 
{
    my($class,@args) = @_;
    my $self = bless {}, $class;
    
    my ($db_id,$cyto_start,$cyto_end,$gene_id,$chromosome) = 
      rearrange([qw(
			    DB_ID
			    CYTO_START
			    CYTO_END
			    EXTERNAL_GENE
			    CHROMOSOME
			    )],@args);
    
   # $db_id  || $self->throw("I need external db id");
   # $cyto_start  || $self->throw("I need cytogenetic position ");
   # $cyto_end  || $self->throw("I need cytogenetic position");

    $self->db_id($db_id);
    $self->cyto_start($cyto_start);  
    $self->cyto_end($cyto_end);
    if (defined $chromosome){$self->chromosome($chromosome);}
    if (defined $gene_id){$self->external_gene($gene_id);}
   	   
  
    
    return $self; 
}



=head2 db_id

 Title   : db_id
 Usage   :
 Function: Get/set the omim_id from NCBI, not the id in the disease table!
 Example :
 Returns : 
 Args    :


=cut


sub db_id 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'_db_id'} = $value;}
  
  return $self->{'_db_id'};
}

=head2 has_gene

 Title   : has_gene
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut


sub has_gene 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'_has_gene'} = $value;}
  
  return $self->{'_has_gene'};
}


=head2 external_gene

 Title   : external_gene
 Usage   :
 Function: Get/Set the gene_symbol, same as in NCBI OMIM, for human.
 Example :
 Returns : 
 Args    :


=cut

sub external_gene 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'_gene_id'} = $value;}
  
  return $self->{'_gene_id'};
}

=head2 ensembl_gene

 Title   : ensembl_gene
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut


sub ensembl_gene 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'ensembl_gene'} = $value;}
  
  return $self->{'ensembl_gene'};
}


=head2 cyto_start

 Title   : cyto_start
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub cyto_start 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'_cyto_start'} = $value;}
  
  return $self->{'_cyto_start'};
}


=head2 cyto_end

 Title   : cyto_end
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut


sub cyto_end 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'_cyto_end'} = $value;}
  
  return $self->{'_cyto_end'};
}



=head2 chromosome

 Title   : chromosome
 Usage   :
 Function: Get/set the chromosome name. X is 'X', not 23!
 Example :
 Returns : 
 Args    :

=cut


sub chromosome 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'chromosome'} = $value;}
  
  return $self->{'chromosome'};
}


=head2 global_position

 Title   : global_position
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut


sub global_position 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'global_position'} = $value;}
  
  return $self->{'global_position'};
}

1;
