package Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::CcdsAdaptor; 

use strict;
use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::ExternalData::CDSTrack::Ccds;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['CcdsUids' , 'cu']);
}

sub _columns {
  my $self = shift;
  return ( 'cu.ccds_uid', 'cu.group_uid', 'cu.latest_version' );
}

sub fetch_by_dbID {
  my $self = shift;
  my $ccds_id = shift;
  
  throw("Require dbID for fetch_by_dbID")
         unless ($ccds_id);
  
  my $constraint = "cu.ccds_uid = '$ccds_id'";
  my ($ccds_obj) = @{ $self->generic_fetch($constraint) };
  
  return $ccds_obj;
}


sub fetch_by_GroupVersion {
  my $self = shift;
  my $gv = shift;
  
  if (!ref $gv || !$gv->isa('Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion') ) {
    throw("Must provide a Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion object");
  }
  
  my $gv_id = $gv->dbID;

  my ($ccds_obj) = $self->fetch_by_group_version_id($gv_id);
  return $ccds_obj;

}


sub fetch_by_group_version_id {
  my $self = shift;
  my $gv_id = shift;
  
  throw("Require group_version_id for fetch_by_group_version_id")
         unless ($gv_id);
  
  my $sql = "SELECT cu.ccds_uid ".
            "FROM CcdsUids cu, GroupVersions gv ".
            "WHERE cu.group_uid = gv.group_uid ".
            "AND gv.group_version_uid = '$gv_id'";
            
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  my ($id) = $sth->fetchrow();
  my $ccds_obj;
  if (defined $id){
    $ccds_obj = $self->fetch_by_dbID($id);
  }
  
  return $ccds_obj;

}




sub _objs_from_sth {
  my ($self, $sth) = @_;
  my @out;
  my ($ccds_id, $group_id, $latest_version); 
  
  $sth->bind_columns( \$ccds_id, \$group_id, \$latest_version); 


  while($sth->fetch()) {
    
    push @out, Bio::EnsEMBL::ExternalData::CDSTrack::Ccds->new(
              -dbID            => $ccds_id,
              -group_id        => $group_id,
              -latest_version  => $latest_version,
              -adaptor         => $self 
    );
  
    
  }
  return \@out;
}

1;
