package Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::CcdsStatusAdaptor; 

use strict;
use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::ExternalData::CDSTrack::CcdsStatus;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['CcdsStatusVals' , 'csv']);
}

sub _columns {
  my $self = shift;
  return ( 'csv.ccds_status_val_uid', 'csv.ccds_status');
}

sub fetch_by_status_id {
  my $self = shift;
  my $ccds_status_val_uid = shift;
  
  throw("Require ccds_status_val_uid for fetch_by_status_id")
         unless ($ccds_status_val_uid);
  
  my $constraint = "csv.ccds_status_val_uid = '$ccds_status_val_uid'";
  my ($csv_obj) = @{ $self->generic_fetch($constraint) };
  return $csv_obj;

}



sub _objs_from_sth {
  my ($self, $sth) = @_;
  my @out;
  my ($dbid, $ccds_status); 
  
  $sth->bind_columns( \$dbid, \$ccds_status); 


  while($sth->fetch()) {
    
    push @out, Bio::EnsEMBL::ExternalData::CDSTrack::CcdsStatus->new(
              -dbID                     => $dbid,
              -ccds_status              => $ccds_status,
              -adaptor                  => $self 
    );
  
    
  }
  return \@out;
}

1;
