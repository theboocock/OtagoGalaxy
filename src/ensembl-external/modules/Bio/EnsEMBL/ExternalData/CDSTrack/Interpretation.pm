package Bio::EnsEMBL::ExternalData::CDSTrack::Interpretation;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Exception qw(throw);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::InterpretationAdaptor;

@ISA = qw(Bio::EnsEMBL::Storable);

sub new {
  my($class,@args) = @_;

  my $self = bless {},$class;

  my ($dbid, $ccds_id, $group_id, $group_version_id, $accession_id, $parent_interpretation_id,
  $date_time, $comment, $val_description, $char_val, $integer_val, $float_val, 
  $interpretation_type_id, $interpretation_subtype_id, $acc_rejection_id, $interpreter_id,
  $program_id, $reftrack_id, $interpretation_subtype, $adaptor) =  
	  rearrange([qw(DBID
	                CCDS_ID
                  GROUP_ID
                  GROUP_VERSION_ID
                  ACCESSION_ID
                  PARENT_INTERPRETATION_ID
                  DATE_TIME
                  COMMENT
                  VAL_DESCRIPTION
                  CHAR_VAL
                  INTEGER_VAL
                  FLOAT_VAL
                  INTERPRETATION_TYPE_ID
                  INTERPRETATION_SUBTYPE_ID
                  ACC_REJECTION_ID
                  INTERPRETER_ID
                  PROGRAM_ID
                  REFTRACK_ID
                  INTERPRETATION_SUBTYPE
                  ADAPTOR
			)],@args);
 
  $self->dbID                       ( $dbid );
  $self->ccds_id                    ( $ccds_id );
  $self->group_id                   ( $group_id );
  $self->group_version_id           ( $group_version_id );
  $self->accession_id               ( $accession_id );
  $self->parent_interpretation_id   ( $parent_interpretation_id );
  $self->date_time                  ( $date_time );
  $self->comment                    ( $comment );
  $self->val_description            ( $val_description );
  $self->char_val                   ( $char_val );
  $self->integer_val                ( $integer_val ); 
  $self->float_val                  ( $float_val );
  $self->interpretation_type_id     ( $interpretation_type_id );
  $self->interpretation_subtype_id  ( $interpretation_subtype_id );
  $self->acc_rejection_id           ( $acc_rejection_id );
  $self->interpreter_id             ( $interpreter_id );
  $self->program_id                 ( $program_id );
  $self->reftrack_id                ( $reftrack_id );
  $self->interpretation_subtype     ( $interpretation_subtype );
  $self->adaptor                    ( $adaptor );
  
  return $self;
}



sub ccds_id {
  my $self = shift;
  $self->{'ccds_uid'} = shift if ( @_ );
  return $self->{'ccds_uid'};
}

sub group_id {
  my $self = shift;
  $self->{'group_uid'} = shift if ( @_ );
  return $self->{'group_uid'};
}

sub group_version_id {
  my $self = shift;
  $self->{'group_version_uid'} = shift if ( @_ );
  return $self->{'group_version_uid'};
}

sub accession_id {
  my $self = shift;
  $self->{'accession_uid'} = shift if ( @_ );
  return $self->{'accession_uid'};
}

sub parent_interpretation_id {
  my $self = shift;
  $self->{'parent_interpretation_uid'} = shift if ( @_ );
  return $self->{'parent_interpretation_uid'};
}

sub date_time {
  my $self = shift;
  $self->{'date_time'} = shift if ( @_ );
  return $self->{'date_time'};
}

sub comment {
  my $self = shift;
  $self->{'comment'} = shift if ( @_ );
  return $self->{'comment'};
}

sub val_description {
  my $self = shift;
  $self->{'val_description'} = shift if ( @_ );
  return $self->{'val_description'};
}

sub char_val {
  my $self = shift;
  $self->{'char_val'} = shift if ( @_ );
  return $self->{'char_val'};
}

sub integer_val {
  my $self = shift;
  $self->{'integer_val'} = shift if ( @_ );
  return $self->{'integer_val'};
}

sub float_val {
  my $self = shift;
  $self->{'float_val'} = shift if ( @_ );
  return $self->{'float_val'};
}

sub interpretation_type_id {
  my $self = shift;
  $self->{'interpretation_type_uid'} = shift if ( @_ );
  return $self->{'interpretation_type_uid'};
}

sub interpretation_subtype_id {
  my $self = shift;
  $self->{'interpretation_subtype_uid'} = shift if ( @_ );
  return $self->{'interpretation_subtype_uid'};
}

sub acc_rejection_id {
  my $self = shift;
  $self->{'acc_rejection_uid'} = shift if ( @_ );
  return $self->{'acc_rejection_uid'};
}

sub interpreter_id {
  my $self = shift;
  $self->{'interpreter_uid'} = shift if ( @_ );
  return $self->{'interpreter_uid'};
}

sub program_id {
  my $self = shift;
  $self->{'program_uid'} = shift if ( @_ );
  return $self->{'program_uid'};
}

sub reftrack_id {
  my $self = shift;
  $self->{'reftrack_uid'} = shift if ( @_ );
  return $self->{'reftrack_uid'};
}

sub interpretation_subtype {
  my $self = shift;
  $self->{'interpretation_subtype'} = shift if ( @_ );
  return $self->{'interpretation_subtype'};
}
1;
