package Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::GroupVersionAdaptor; 

use strict;
use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['GroupVersions' , 'gv'], ['Groups' , 'g']);
}

sub _columns {
  my $self = shift;
  return ( 'gv.group_version_uid', 'gv.group_uid', 'gv.version', 'gv.ncbi_build_number',
   'gv.first_ncbi_build_version', 'gv.last_ncbi_build_version', 'gv.gene_id', 
   'gv.location_count', 'gv.ccds_status_val_uid', 'gv.ccds_version', 'gv.was_public',
   'g.current_version', 'g.tax_id', 'g.chromosome', 'g.orientation');
}

sub _left_join {
  return ( [ 'Groups', "g.group_uid = gv.group_uid" ]);
}



sub fetch_by_dbID { 
  my $self = shift;
  my $gv_id = shift;
  
  throw("Require dbID for fetch_by_dbID")
         unless ($gv_id);
  
  my $constraint = "gv.group_version_uid = '$gv_id'";
  my ($gv_obj) = @{ $self->generic_fetch($constraint) };

  if (defined $gv_obj) {
    print "Got gv.group_version_uid = '$gv_id'\n";
  } else {
    print "Unable to fetch $gv_id\n";
    exit;
  }
  return $gv_obj;
}


sub fetch_all_by_accession {
  my $self = shift;
  my $acc = shift;
  my $version = shift;
  my @GroupVersion_array;
  
  throw("Require transcript_stable_id for fetch_all_by_accession")
         unless ($acc);
  
  my $sql = "SELECT agv.group_version_uid ".
            "FROM Accessions a, Accessions_GroupVersions agv ".
            "WHERE a.accession_uid = agv.accession_uid ".
            "AND a.nuc_acc = '$acc'";
  if ($version){
    $sql = join " ", $sql, "AND a.nuc_version = '$version'";          
  }          
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
  
    push @GroupVersion_array, $self->fetch_by_dbID($id);
  }
  return \@GroupVersion_array;
  
  
}


sub fetch_all_current_by_accession {
  my $self = shift;
  my $build_number = shift;
  my $acc = shift;
  my $version = shift;
  
  my @GroupVersion_array;
  
  throw("Require ncbi_build_number for fetch_all_current_by_accession")
         unless ($build_number);
  
  throw("Require transcript_stable_id for fetch_all_current_by_accession")
         unless ($acc);
  
  if ($build_number){
    $build_number = ncbi_build_number($build_number);
  }
  
  
  my $sql = "SELECT agv.group_version_uid ".
            "FROM Accessions a, Accessions_GroupVersions agv, GroupVersions gv ".
            "WHERE a.accession_uid = agv.accession_uid ".
            "AND a.nuc_acc = '$acc' ".
            "AND agv.group_version_uid = gv.group_version_uid ".
            "AND gv.ncbi_build_number = '$build_number' ";
  if ($version){
    $sql = join " ", $sql, "AND a.nuc_version = '$version'";          
  }          
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
  
    push @GroupVersion_array, $self->fetch_by_dbID($id);
  }
  return \@GroupVersion_array;
  
  
}


sub fetch_all_by_status {
  my $self = shift;
  my $status = shift;
  my $tax_id = shift;
  my $build_number = shift;
  
  
  
  throw("Require status for fetch_all_by_status")
         unless ($status);
  
  $status = "\u\L$status";
  
  my %ccds_status = (
    'Candidate' => 1,
    'Pre-release' => 1,
    'Public' => 1,
    'Under review, update' => 1,
    'Reviewed, update pending' => 1,
    'Under review, withdrawal' => 1,
    'Reviewed, withdrawal pending' => 1,
    'Withdrawn' => 1,
    'Unknown' => 1,
    'Preliminary' => 1,
    'Withdrawn, inconsistent annotation' => 1,
  );
  
  unless (exists $ccds_status{$status}){
    print STDERR "status must be one of:\n";
    foreach my $k (keys %ccds_status){
      print STDERR "\'$k\', ";
    }
    print STDERR "\n";
    throw ("status \'$status\' is not recognized");
    return;
  }
  
  
  my @GroupVersion_array;
  
  my $sql = "SELECT gv.group_version_uid ".
            "FROM GroupVersions gv, CcdsStatusVals csv ".
            "WHERE gv.ccds_status_val_uid = csv.ccds_status_val_uid ".
            "AND csv.ccds_status = '$status'";
  if ($tax_id){
    $sql = "SELECT gv.group_version_uid ".
            "FROM GroupVersions gv, CcdsStatusVals csv, Groups g ".
            "WHERE gv.ccds_status_val_uid = csv.ccds_status_val_uid ".
            "AND g.group_uid = gv.group_uid ".
            "AND csv.ccds_status = '$status' ".
            "AND g.tax_id = '$tax_id'";
  }
  
  if ($build_number){
    $build_number = ncbi_build_number($build_number);
    $sql = join " ", $sql, "AND gv.ncbi_build_number = '$build_number'";
  }
 
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
    push @GroupVersion_array, $self->fetch_by_dbID($id);
  }
  return \@GroupVersion_array;

}

sub fetch_all_by_ensembl_withdrawal_action {
  my $self = shift;
  my $action = shift;
  my $tax_id = shift;
  
  
  
  throw("Require action for fetch_all_by_ensembl_withdrawal_action")
         unless ($action);
  
  $action = "\u\L$action";
  
  my %withdrawal_action = (
    'Keep' => 1,
    'Remove transcript' => 1,
    'Remove gene' => 1,
  );
  
  unless (exists $withdrawal_action{$action}){
    print STDERR "action must be one of:\n";
    foreach my $k (keys %withdrawal_action){
      print STDERR "\'$k\', ";
    }
    print STDERR "\n";
    throw ("action \'$action\' is not recognized");
    return;
  }
  
  
  my @GroupVersion_array;
  
  #checks that their status is still withdrawn...
  
  my $sql = "SELECT gv.group_version_uid ".
            "FROM GroupVersions gv, CcdsUids cu, EnsemblWithdrawals ew, CcdsStatusVals csv ".
            "WHERE gv.group_uid = cu.group_uid ".
	    "AND cu.ccds_uid = ew.ccds_uid ".
	    "AND csv.ccds_status_val_uid = gv.ccds_status_val_uid ".
	    "AND csv.ccds_status like 'Withdrawn%' ".
            "AND ew.action = '$action'";
  if ($tax_id){
    $sql = "SELECT gv.group_version_uid ".
            "FROM GroupVersions gv, CcdsUids cu, EnsemblWithdrawals ew, Groups g, CcdsStatusVals csv  ".
            "WHERE gv.group_uid = cu.group_uid ".
            "AND g.group_uid = gv.group_uid ".
	    "AND cu.ccds_uid = ew.ccds_uid ".
	    "AND csv.ccds_status_val_uid = gv.ccds_status_val_uid ".
	    "AND csv.ccds_status like 'Withdrawn%' ".
            "AND ew.action = '$action' ".
            "AND g.tax_id = '$tax_id'";
  }
  
 
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
    push @GroupVersion_array, $self->fetch_by_dbID($id);
  }
  return \@GroupVersion_array;

}


sub fetch_all_by_CCDS_ID {
  my $self = shift;
  my $ccds_id = shift;
  my $version = "";
  my @GroupVersion_array;
  
  $ccds_id =~s/CCDS//i;
  if ($ccds_id =~/(\d+)\.(\d*)/){
    $ccds_id = $1;
    $version = $2;
  }
  
  throw("Require CCDS_id for fetch_by_CCDS_ID")
         unless ($ccds_id);
  
  
  my $sql = "SELECT gv.group_version_uid ".
            "FROM GroupVersions gv, CcdsUids c ".
            "WHERE gv.group_uid = c.group_uid ".
            "AND c.ccds_uid = '$ccds_id'";
  if ($version){
    $sql = join " ", $sql, "AND gv.ccds_version = '$version'";
  }
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
    push @GroupVersion_array, $self->fetch_by_dbID($id);
  }
  return \@GroupVersion_array;

}

sub fetch_all_current {
  my $self = shift;
  my $tax_id = shift;
  my $build_number = shift;
  
  my @GroupVersion_array;
  
  my $sql = "SELECT gv.group_version_uid ".
            "FROM GroupVersions gv, Groups g ".
            "WHERE gv.group_uid = g.group_uid ".
            #"AND gv.version > g.current_version ";
            "AND gv.version = g.current_version ";
  
  if ($tax_id){
    $sql = join " ", $sql, "AND g.tax_id = '$tax_id' ";
  }
  if ($build_number){
    $build_number = ncbi_build_number($build_number);
    $sql = join " ", $sql, "AND gv.ncbi_build_number = '$build_number'";
  }
  
  print "$sql\n";

  my $sth = $self->prepare($sql);
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
    print "Got gv.group_version_uid $id, now fetching...\n";
    push @GroupVersion_array, $self->fetch_by_dbID($id);
  }
  return \@GroupVersion_array;
  
}

sub ncbi_build_number {
  my $build_number = shift;
  
  if ($build_number=~/[NCBIM]+(\d+)/){
    $build_number = $1;
  } elsif ($build_number=~/[GRCh]+(\d+)/) {
    $build_number = $1;
  }
  return $build_number;

}


#sub fetch_all_location_changed {
#  my $self = shift;
#  my $tax_id = shift;
#  
#  my @GroupVersion_array;
#  
#  
#  my $sql = "SELECT gv.group_version_uid ".
#            "FROM GroupVersions gv, CcdsUids cu, Interpretations i, InterpretationSubtypes isub ".
#            "WHERE gv.group_uid = cu.group_uid ".
#            "AND cu.ccds_uid = i.ccds_uid ".
#	    "AND i.interpretation_subtype_uid = isub.interpretation_subtype_uid ".
#	    "AND isub.interpretation_subtype = 'Location changed' ".
#	    "AND i.val_description = 'New CCDS' ";
#  if ($tax_id){
#     $sql = "SELECT gv.group_version_uid ".
#            "FROM Groups g, GroupVersions gv, CcdsUids cu, Interpretations i, InterpretationSubtypes isub ".
#            "WHERE gv.group_uid = cu.group_uid ".
#            "AND cu.ccds_uid = i.ccds_uid ".
#	    "AND i.interpretation_subtype_uid = isub.interpretation_subtype_uid ".
#	    "AND isub.interpretation_subtype = 'Location changed' ".
#	    "AND i.val_description = 'New CCDS' ".
#	    "AND g.group_uid = gv.group_uid ".
#	    "AND g.tax_id = '$tax_id'";
#  }
#  
# 
#  my $sth = $self->prepare($sql);
#  
#  $sth->execute();
#  while ( my $id = $sth->fetchrow()) {
#    push @GroupVersion_array, $self->fetch_by_dbID($id);
#  }
#  return \@GroupVersion_array;
#
#}


sub fetch_all_location_changed {
  my $self = shift;
  my $tax_id = shift;
  
  my @GroupVersion_aoa;
  
  my $sql = "SELECT i.ccds_uid, i.char_val ".
            "FROM Interpretations i, InterpretationSubtypes isub ".
            "WHERE i.interpretation_subtype_uid = isub.interpretation_subtype_uid ".
	    "AND isub.interpretation_subtype = 'Location changed' ".
	    "AND i.val_description = 'New CCDS' ";
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my ($old_ccds_id, $new_ccds_id) = $sth->fetchrow()) {
    
    my @old_GroupVersions;
    my @new_GroupVersions;

    
    my $sql1 = "SELECT gv.group_version_uid ".
              "FROM GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $old_ccds_id ";
    if ($tax_id){
       $sql1 = "SELECT gv.group_version_uid ".
              "FROM Groups g, GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $old_ccds_id ".
	      "AND g.group_uid = gv.group_uid ".
	      "AND g.tax_id = '$tax_id'";
    
    }
    
    my $sth = $self->prepare($sql1);
    $sth->execute();
    while ( my $id = $sth->fetchrow()) {
      push @old_GroupVersions, $self->fetch_by_dbID($id);
    }
    
    my $sql2 = "SELECT gv.group_version_uid ".
              "FROM GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $new_ccds_id ";
    if ($tax_id){
       $sql2 = "SELECT gv.group_version_uid ".
              "FROM Groups g, GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $new_ccds_id ".
	      "AND g.group_uid = gv.group_uid ".
	      "AND g.tax_id = '$tax_id'";
    
    }
    
    $sth = $self->prepare($sql2);
    $sth->execute();
    while ( my $id = $sth->fetchrow()) {
      push @new_GroupVersions, $self->fetch_by_dbID($id);
    }
    
    foreach my $old_gv (@old_GroupVersions){
      foreach my $new_gv (@new_GroupVersions){
	my @tmp = ($old_gv, $new_gv);
	push @GroupVersion_aoa, [@tmp];
      }
    }
    
  }
  
#  for my $row (@GroupVersion_aoa){
#    print "@$row\n";
#  }
  
  return \@GroupVersion_aoa;

}


#sub fetch_all_strand_changed {
#  my $self = shift;
#  my $tax_id = shift;
#  
#  my @GroupVersion_array;
#  
#  my $sql = "SELECT gv.group_version_uid ".
#            "FROM GroupVersions gv, CcdsUids cu, Interpretations i, InterpretationSubtypes isub ".
#            "WHERE gv.group_uid = cu.group_uid ".
#            "AND cu.ccds_uid = i.ccds_uid ".
#	    "AND i.interpretation_subtype_uid = isub.interpretation_subtype_uid ".
#	    "AND isub.interpretation_subtype = 'Strand changed' ".
#	    "AND i.val_description = 'New CCDS' ";
#  if ($tax_id){
#     $sql = "SELECT gv.group_version_uid ".
#            "FROM Groups g, GroupVersions gv, CcdsUids cu, Interpretations i, InterpretationSubtypes isub ".
#            "WHERE gv.group_uid = cu.group_uid ".
#            "AND cu.ccds_uid = i.ccds_uid ".
#	    "AND i.interpretation_subtype_uid = isub.interpretation_subtype_uid ".
#	    "AND isub.interpretation_subtype = 'Strand changed' ".
#	    "AND i.val_description = 'New CCDS' ".
#	    "AND g.group_uid = gv.group_uid ".
#	    "AND g.tax_id = '$tax_id'";
#	    
#  }
#  
# 
#  my $sth = $self->prepare($sql);
#  
#  $sth->execute();
#  while ( my $id = $sth->fetchrow()) {
#    push @GroupVersion_array, $self->fetch_by_dbID($id);
#  }
#  return \@GroupVersion_array;
#
#}

sub fetch_all_strand_changed {
  my $self = shift;
  my $tax_id = shift;
  
  my @GroupVersion_aoa;
  
  my $sql = "SELECT i.ccds_uid, i.char_val ".
            "FROM Interpretations i, InterpretationSubtypes isub ".
            "WHERE i.interpretation_subtype_uid = isub.interpretation_subtype_uid ".
	    "AND isub.interpretation_subtype = 'Strand changed' ".
	    "AND i.val_description = 'New CCDS' ";
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my ($old_ccds_id, $new_ccds_id) = $sth->fetchrow()) {
    
    my @old_GroupVersions;
    my @new_GroupVersions;

    
    my $sql1 = "SELECT gv.group_version_uid ".
              "FROM GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $old_ccds_id ";
    if ($tax_id){
       $sql1 = "SELECT gv.group_version_uid ".
              "FROM Groups g, GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $old_ccds_id ".
	      "AND g.group_uid = gv.group_uid ".
	      "AND g.tax_id = '$tax_id'";
    
    }
    
    my $sth = $self->prepare($sql1);
    $sth->execute();
    while ( my $id = $sth->fetchrow()) {
      push @old_GroupVersions, $self->fetch_by_dbID($id);
    }
    
    my $sql2 = "SELECT gv.group_version_uid ".
              "FROM GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $new_ccds_id ";
    if ($tax_id){
       $sql2 = "SELECT gv.group_version_uid ".
              "FROM Groups g, GroupVersions gv, CcdsUids cu ".
              "WHERE gv.group_uid = cu.group_uid ".
              "AND cu.ccds_uid = $new_ccds_id ".
	      "AND g.group_uid = gv.group_uid ".
	      "AND g.tax_id = '$tax_id'";
    
    }
    
    $sth = $self->prepare($sql2);
    $sth->execute();
    while ( my $id = $sth->fetchrow()) {
      push @new_GroupVersions, $self->fetch_by_dbID($id);
    }
    
    foreach my $old_gv (@old_GroupVersions){
      foreach my $new_gv (@new_GroupVersions){
	my @tmp = ($old_gv, $new_gv);
	push @GroupVersion_aoa, [@tmp];
      }
    }
    
  }
  
#  for my $row (@GroupVersion_aoa){
#    print "@$row\n";
#  }
  
  return \@GroupVersion_aoa;

}



sub _objs_from_sth {
  my ($self, $sth) = @_;
  my @out;
  my ($dbid, $group_id, $group_version, $ncbi_build_number); 
  my ($first_ncbi_build_version, $last_ncbi_build_version, $ncbi_gene_id);
  my ($location_count, $ccds_status_val_id, $ccds_version, $was_public, $adaptor);
  my ($current_version, $tax_id, $chromosome, $strand);
  
  $sth->bind_columns( \$dbid, \$group_id, \$group_version, \$ncbi_build_number,
  \$first_ncbi_build_version, \$last_ncbi_build_version, \$ncbi_gene_id,
  \$location_count, \$ccds_status_val_id, \$ccds_version, \$was_public,
  \$current_version, \$tax_id, \$chromosome, \$strand); 



  while($sth->fetch()) {
    
    push @out, Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion->new(
              -dbID                     => $dbid,
              -group_id                 => $group_id,
              -group_version            => $group_version,
              -ncbi_build_number        => $ncbi_build_number,
              -first_ncbi_build_version => $first_ncbi_build_version,
              -last_ncbi_build_version  => $last_ncbi_build_version,
              -ncbi_gene_id             => $ncbi_gene_id,
              -location_count           => $location_count,
              -ccds_status_val_id       => $ccds_status_val_id,
              -ccds_version             => $ccds_version,
              -was_public               => $was_public,
              -current_version          => $current_version,
              -tax_id                   => $tax_id,
              -chromosome               => $chromosome eq 'XY' ? 'X' : $chromosome,
              -strand                   => $strand eq '+' ? '1' : '-1',
              -adaptor                  => $self 
    );
  
    
  }
  return \@out;
}



1;
