#
# EnsEMBL module for  Bio::EnsEMBL::ExternalData::Expression::SeqTag
#
# Cared for by EnsEMBL (www.ensembl.org)
#
# Copyright GRL and EBI
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::Expression::SeqTag

=head1 SYNOPSIS

    @contig = $db->get_Contigs();

    $clone = $db->get_Clone();

    @genes    = $clone->get_all_Genes();

=head1 DESCRIPTION

Represents information on one Clone

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::ExternalData::Expression::SeqTag;
use vars qw(@ISA);
use strict;
use Bio::DBLinkContainerI;


@ISA = qw(Bio::DBLinkContainerI);


=head2 new

 Title   : new
 Usage   : 
 Function: 
 Example : 
 Returns : SeqTag object
 Args    :


=cut


sub new {
    my ($class,$adaptor,@args) = @_;

    my $self = {};
    bless $self,$class;

    $self->adaptor($adaptor);
    $self->_set_from_args(@args);

    return $self;
   
}



=head2 add_DBLink

 Title   : add_DBLink
 Usage   : $self->add_DBLink($ref)
 Function: adds a link object
 Example :
 Returns :
 Args    :


=cut

sub add_DBLink{
   my ($self,$com) = @_;
   if( ! $com->isa('Bio::Annotation::DBLink') ) {
       $self->throw("Is not a link object but a  [$com]");
   }
   push(@{$self->{'link'}},$com);
}

=head2 each_DBLink

 Title   : each_DBLink
 Usage   : foreach $ref ( $self->each_DBlink() )
 Function: gets an array of DBlink of objects
 Example :
 Returns :
 Args    :


=cut

sub each_DBLink{
   my ($self) = @_;

   return @{$self->{'link'}} if defined $self->{'link'};
}




=head2 id

 Title   : id
 Usage   : $obj->id($newval)
 Function: 
 Example : 
 Returns : value of tag id
 Args    : newvalue (optional)


=cut

sub id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_id'} = $value;
    }
    return $obj->{'_id'};
}

=head2 source

 Title   : source
 Usage   : $obj->source($newval)
 Function: 
 Example : 
 Returns : value of source
 Args    : newvalue (optional)


=cut

sub source {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_source'} = $value;
    }
    return $obj->{'_source'};

}



=head2 name

 Title   : name
 Usage   : $obj->name($newval)
 Function: 
 Example : 
 Returns : value  of name
 Args    : newvalue (optional)


=cut

sub name {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_name'} = $value;
    }
    return $obj->{'_name'};

}




=head2 frequency

 Title   : frequency
 Usage   : $obj->frequency($newval)
 Function: 
 Example : 
 Returns : value  of frequency
 Args    : newvalue (optional)


=cut

sub frequency {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_frequency'} = $value;
    }
    return $obj->{'_frequency'};

}

=head2 relative_frequency

 Title   : relative_frequency
 Usage   : $obj->realtive_frequency($newval)
 Function: 
 Example : 
 Returns : value  of realtive_frequency
 Args    : newvalue (optional)


=cut

sub relative_frequency {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_relative_frequency'} = $value;
    }
    return $obj->{'_relative_frequency'};

}


=head2 adaptor

 Title   : adaptor
 Usage   : $obj->adaptor($newval)
 Function: 
 Example : 
 Returns : value of adaptor
 Args    : newvalue (optional)


=cut

sub adaptor {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'adaptor'} = $value;
    }
    return $obj->{'adaptor'};

}





sub _set_from_args {

    my ($self,@args)=@_;

    my ($id,$source,$name,$frequency,$relative_frequency)=@args;

    $self->id($id);
    $self->source($source);
    $self->name($name);
    $self->frequency($frequency);
    $self->relative_frequency($relative_frequency);
}














