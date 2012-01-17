package Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::AccessionAdaptor; 

use strict;
use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::ExternalData::CDSTrack::Accession;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['Accessions' , 'a'],['Organizations', 'o']);
}

sub _columns {
  my $self = shift;
  return ( 'a.accession_uid', 'a.nuc_acc', 'a.nuc_version', 'a.nuc_gi', 'a.prot_acc', 
  'a.prot_version', 'a.prot_gi', 'a.organization_uid', 'a.alive',
  'o.name', 'o.approval_authority');
}

sub _left_join {
  return ( [ 'Organizations', "a.organization_uid = o.organization_uid" ]);
}

sub fetch_by_dbID {
  my $self = shift;
  my $acc_id = shift;
  
  throw("Require dbID for fetch_by_dbID")
         unless ($acc_id);
  
  my $constraint = "a.accession_uid = '$acc_id'";
  my ($acc_obj) = @{ $self->generic_fetch($constraint) };
  
  return $acc_obj;
}

#sub fetch_all_status_id {
#  my $self = shift;
#  my $acc_id = shift;
#  my $acc_version = shift;
#  
#  throw("Require transcript_stable_id for fetch_all_status")
#         unless ($acc_id);
#  
#  my @status;
#  
#  my $sql = "SELECT agv.ccds_status_val_uid ".
#            "FROM Accessions_GroupVersions agv, Accessions a ".
#            "WHERE a.accession_uid = agv.accession_uid ".
#            "AND a.nuc_acc = '$acc_id'";
#   
#  if ($acc_version){
#    $sql = join "", $sql, " AND a.nuc_version = '$acc_version'";
#  }          
#  
#  my $sth = $self->prepare($sql);
#  $sth->execute();
#  
#  while ( my $status_id = $sth->fetchrow()) {
#    push @status, $status_id;
#  }
#
#  return \@status;
#
#}


sub fetch_all_by_transcript_stable_id {
  my $self = shift;
  my $trans_acc = shift;
  my $version = shift;
  
  throw("Require transcript stable_id for fetch_all_by_transcript_stable_id")
         unless ($trans_acc);

  
  my $constraint = "a.nuc_acc = '$trans_acc'";
  if ($version){
    $constraint .= " && a.nuc_version = '$version'";
  }
  my @acc_objs = @{ $self->generic_fetch($constraint) };
  return \@acc_objs;
}

sub fetch_all_by_translation_stable_id {
  my $self = shift;
  my $trans_acc = shift;
  my $version = shift;
  
  throw("Require translation stable_id for fetch_all_by_translation_stable_id")
         unless ($trans_acc);
  
  my $constraint = "a.prot_acc = '$trans_acc'";
  if ($version){
    $constraint .= " && a.prot_version = '$version'";
  }
  my  @acc_objs = @{ $self->generic_fetch($constraint) };
  return \@acc_objs;
}

sub fetch_all_by_organization_id {
  my $self = shift;
  my $org_id = shift;
  
  throw("Require organization_id for fetch_all_by_organization_id")
         unless ($org_id);
  
  my $constraint = "a.organization_uid = '$org_id'";
  my @acc_objs = @{ $self->generic_fetch($constraint) };
  return \@acc_objs;
}

sub fetch_all_alive {
  my $self = shift;
  my $constraint = "a.alive = '1'";
  my @acc_objs = @{ $self->generic_fetch($constraint) };
  return \@acc_objs;
}


sub fetch_all_by_GroupVersion {
  my $self = shift;
  my $gv = shift;
  
  if (!ref $gv || !$gv->isa('Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion') ) {
    throw("Must provide a Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion object");
  }
  
  my $gv_id = $gv->dbID;
  my @acc_objs;
  @acc_objs = @{$self->fetch_all_by_group_version_id($gv_id)};
  return \@acc_objs;

}


sub fetch_all_by_group_version_id {
  my $self = shift;
  my $gv_id = shift;
  my @acc_objs;
  
  
  throw("Require group_version_id for fetch_all_by_group_version_id")
         unless ($gv_id);
  
  my $sql = "SELECT agv.accession_uid ".
            "FROM Accessions_GroupVersions agv ".
            "WHERE agv.group_version_uid = '$gv_id'";
            
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
    push @acc_objs, $self->fetch_by_dbID($id);
  }
  return \@acc_objs;

}


sub _objs_from_sth {
  my ($self, $sth) = @_;
  my @out;
  my ($accession_uid, $transcript_stable_id, $transcript_version); 
  my ($transcript_ncbi_id, $translation_stable_id, $translation_version, $translation_ncbi_id);
  my ($organization_id, $alive, $organization, $approval_authority);
  
  $sth->bind_columns( \$accession_uid, \$transcript_stable_id, \$transcript_version ,
  \$transcript_ncbi_id, \$translation_stable_id, \$translation_version, \$translation_ncbi_id,
  \$organization_id, \$alive, \$organization, \$approval_authority); 


  while($sth->fetch()) {
    
    push @out, Bio::EnsEMBL::ExternalData::CDSTrack::Accession->new(
              -dbID                   => $accession_uid,
              -transcript_stable_id   => $transcript_stable_id,
              -transcript_version     => $transcript_version,
              -transcript_ncbi_id      => $transcript_ncbi_id,
              -translation_stable_id  => $translation_stable_id,
              -translation_version    => $translation_version,
              -translation_ncbi_id    => $translation_ncbi_id,
              -organization_id        => $organization_id,
              -alive                  => $alive,
              -organization           => $organization,
              -approval_authority     => $approval_authority,
              -adaptor                => $self 
    );
  
    
  }
  return \@out;
}


1;
