package Bio::EnsEMBL::ExternalData::Mole::Comment;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::Mole::DBSQL::CommentAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);


sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);

  my ($dbid, $adaptor, $entry_id, 
      $comment_key, $comment_value ) = 
      rearrange([qw(DBID
                    ADAPTOR
                    ENTRY_ID
                    COMMENT_KEY
                    COMMENT_VALUE 
                )],@_); 

  $self->dbID              ( $dbid );
  $self->adaptor           ( $adaptor );
  $self->entry_id          ( $entry_id ); 
  $self->comment_key       ( $comment_key ) if (defined $comment_key);
  $self->comment_value     ( $comment_value )  if (defined $comment_value);
  return $self; # success - we hope!
}


sub entry_id {
  my $self = shift;
  $self->{'entry_id'} = shift if ( @_ );
  return $self->{'entry_id'};
}

sub comment_key {
  my $self = shift;
  $self->{'comment_key'} = shift if ( @_ );
  return $self->{'comment_key'};
}

sub comment_value {
  my $self = shift;
  $self->{'comment_value'} = shift if ( @_ );
  return $self->{'comment_value'};
}

1;



