package Bio::EnsEMBL::ExternalData::Mole::Entry;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw warning);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::EntryAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);
  
  my ($dbid, $accession_version, 
      $name, $topology, $molecule_type,
      $data_class, $tax_division, $sequence_length,
      $last_updated, $first_submitted,
      $accession_obj, $dbxref_objs, $comment_objs,
      $description_obj,$sequence_obj, $taxonomy_obj) =  
	  rearrange([qw(DBID
	                ACCESSION_VERSION	
                        NAME
                        TOPOLOGY
                        MOLECULE_TYPE
                        DATA_CLASS
                        TAX_DIVISION 
                        SEQUENCE_LENGTH
                        LAST_UPDATED
                        FIRST_SUBMITTED
                        ACCESSION_OBJ
                        DBXREF_OBJS
                        COMMENT_OBJS
                        DESCRIPTION_OBJ
                        SEQUENCE_OBJ
                        TAXONOMY_OBJ
			)],@_);

  $self->dbID              ( $dbid );
  $self->accession_version ( $accession_version );
  $self->name              ( $name );
  $self->topology          ( $topology );
  $self->molecule_type     ( $molecule_type );
  $self->data_class        ( $data_class );
  $self->tax_division      ( $tax_division );
  $self->sequence_length   ( $sequence_length ) if (defined $sequence_length);
  $self->last_updated      ( $last_updated ) if (defined $last_updated);    
  $self->first_submitted   ( $first_submitted ) if (defined $first_submitted);

  if(!ref($accession_obj) || !$accession_obj->isa('Bio::EnsEMBL::ExternalData::Mole::Accession')) {
    throw('-ACCESSION_OBJ argument must be a Bio::EnsEMBL::ExternalData::Mole::Accession not '.
          $accession_obj);
  }
  $self->accession_obj($accession_obj);

  if ($dbxref_objs) {
    $self->{'dbxref_objs'} = $dbxref_objs;
  } else {
    $self->{'dbxref_objs'} = [];
  }

  if ($comment_objs) {
    $self->{'comment_objs'} = $comment_objs;
  } else {
    $self->{'comment_objs'} = [];
  }

  if (defined $description_obj) { 
    if(!ref($description_obj) || !$description_obj->isa('Bio::EnsEMBL::ExternalData::Mole::Description')) {
      throw('-DESCRIPTION_OBJ argument must be a Bio::EnsEMBL::ExternalData::Mole::Description not '.
            $description_obj);
    }
    $self->description_obj($description_obj);
  } else {
    warning("No description object for Entry ".$self->accession_version);
  }

  if (defined $sequence_obj) {
    if(!ref($sequence_obj) || !$sequence_obj->isa('Bio::EnsEMBL::ExternalData::Mole::Sequence')) {
      throw('-SEQUENCE_OBJ argument must be a Bio::EnsEMBL::ExternalData::Mole::Sequence not '.
            $sequence_obj);
    }
    $self->sequence_obj($sequence_obj);
  } else {
    warning("No sequence object for Entry ".$self->accession_version);
  }

  if (defined $taxonomy_obj) {
    if(!ref($taxonomy_obj) || !$taxonomy_obj->isa('Bio::EnsEMBL::ExternalData::Mole::Taxonomy')) {
      throw('-DESCRIPTION_OBJ argument must be a Bio::EnsEMBL::ExternalData::Mole::Taxonomy not '.
            $taxonomy_obj);
    }
    $self->taxonomy_obj($taxonomy_obj);
  } else {
    warning("No taxonomy object for Entry ".$self->accession_version);
  }
  return $self; # success - we hope!
}


sub accession_version {
  my $self = shift;
  $self->{'accession_version'} = shift if ( @_ );
  return $self->{'accession_version'};
}

sub name {
  my $self = shift;
  $self->{'name'} = shift if ( @_ );
  return $self->{'name'};
}

sub topology {
  my $self = shift;
  $self->{'topology'} = shift if ( @_ );
  return $self->{'topology'};
}

sub molecule_type {
  my $self = shift;
  $self->{'molecule_type'} = shift if ( @_ );
  return $self->{'molecule_type'};
}

sub data_class {
  my $self = shift;
  $self->{'data_class'} = shift if ( @_ );
  return $self->{'data_class'};
}

sub tax_division {
  my $self = shift;
  $self->{'tax_division'} = shift if ( @_ );
  return $self->{'tax_division'};
}

sub sequence_length {
  my $self = shift;
  $self->{'sequence_length'} = shift if ( @_ );
  return $self->{'sequence_length'};
}

sub last_updated {
  my $self = shift;                  
  $self->{'last_updated'} = shift if ( @_);
  return $self->{'last_updated'};
}

sub first_submitted {
  my $self = shift;                      
  $self->{'first_submitted'} = shift if ( @_);
  return $self->{'first_submitted'};
}
      


sub accession_obj {
  my $self = shift;

  if(@_) {
    my $acc = shift;
    if(defined($acc) && (!ref($acc) || !$acc->isa('Bio::EnsEMBL::ExternalData::Mole::Accession'))) {
      throw('accession_obj argument must be a Bio::EnsEMBL::ExternalData::Mole::Accession');
    }
    $self->{'accession_obj'} = $acc;
  }

  return $self->{'accession_obj'};
}

sub get_all_DBXrefs {
  my ($self) = @_;
  if (!defined $self->{'dbxref_objs'} && defined $self->adaptor()) {
    $self->{'dbxref_objs'} = $self->adaptor()->db()->get_DBXrefAdaptor()->fetch_all_by_Entry($self);
  }
  return $self->{'dbxref_objs'};
}

sub comment_objs {
  my $self = shift;
  my $comments = shift;

  if( ! exists $self->{'comment_objs'} ) {
    $self->{'comment_objs'} = [];
  }

  foreach my $comment ( @$comments ) {
    if( ! $comment->isa( "Bio::EnsEMBL::ExternalData::Mole::Comment" )) {
     throw( "Argument to add_Comments has to be a Bio::EnsEMBL::ExternalData::Mole::Comment" );
    }
    push( @{$self->{'comment_objs'}}, $comment );
  }

  return $self->{'comment_objs'};
}

sub description_obj {
  my $self = shift;

  if(@_) {
    my $desc = shift;
    if(defined($desc) && (!ref($desc) || !$desc->isa('Bio::EnsEMBL::ExternalData::Mole::Description'))) {
      throw('description_obj argument must be a Bio::EnsEMBL::ExternalData::Mole::Description');
    }
    $self->{'description_obj'} = $desc;
  }

  return $self->{'description_obj'};
}

sub sequence_obj {
  my $self = shift;

  if(@_) {
    my $seq = shift;
    if(defined($seq) && (!ref($seq) || !$seq->isa('Bio::EnsEMBL::ExternalData::Mole::Sequence'))) {
      throw('sequence_obj argument must be a Bio::EnsEMBL::ExternalData::Mole::Sequence');
    }
    $self->{'sequence_obj'} = $seq;
  }

  return $self->{'sequence_obj'};
}

sub taxonomy_obj {
  my $self = shift;

  if(@_) {
    my $taxonomy = shift;
    if(defined($taxonomy) && (!ref($taxonomy) || !$taxonomy->isa('Bio::EnsEMBL::ExternalData::Mole::Taxonomy'))) {
      throw('taxonomy_obj argument must be a Bio::EnsEMBL::ExternalData::Mole::Taxonomy');
    }
    $self->{'taxonomy_obj'} = $taxonomy;
  }

  return $self->{'taxonomy_obj'};
}
1;
