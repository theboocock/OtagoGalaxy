package Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::LocationAdaptor; 

use strict;
use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::ExternalData::CDSTrack::Location;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning stack_trace_dump );
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars '@ISA';
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);


sub _tables {
  my $self = shift;
  return (['Locations' , 'l']);
}

sub _columns {
  my $self = shift;
  return ( 'l.location_uid', 'l.chr_start', 'l.chr_stop');
}

sub fetch_by_dbID {
  my $self = shift;
  my $loc_id = shift;
  
  throw("Require dbID for fetch_by_dbID")
         unless ($loc_id);
  
  my $constraint = "l.location_uid = '$loc_id'";
  my ($loc_obj) = @{ $self->generic_fetch($constraint) };
  
  return $loc_obj;
}


sub fetch_all_by_GroupVersion {
  my $self = shift;
  my $gv = shift;
  
  if (!ref $gv || !$gv->isa('Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion') ) {
    throw("Must provide a Bio::EnsEMBL::ExternalData::CDSTrack::GroupVersion object");
  }
  
  my $chr = $gv->chromosome;
  my $gv_id = $gv->dbID;

  my (@loc_objs) = @{$self->fetch_all_by_group_version_id($gv_id, $chr)};
  return \@loc_objs;

}


sub fetch_all_by_group_version_id {
  my $self = shift;
  my $gv_id = shift;
  my $chr = shift;
  my @loc_objs;
  
  throw("Require group_version_id for fetch_by_group_version_id")
         unless ($gv_id);
  throw("Require chromosome for fetch_by_group_version_id")
         unless ($chr);
  
  my $sql = "SELECT lgv.location_uid ".
            "FROM Locations_GroupVersions lgv ".
            "WHERE lgv.group_version_uid = $gv_id ".
            "AND lgv.chromosome = '$chr'";
            
  
  my $sth = $self->prepare($sql);
  
  $sth->execute();
  while ( my $id = $sth->fetchrow()) {
    push @loc_objs, $self->fetch_by_dbID($id);
  }
  return \@loc_objs;
  
}



sub _objs_from_sth {
  my ($self, $sth) = @_;
  my @out;
  my ($dbid, $exon_start, $exon_end); 

  $sth->bind_columns( \$dbid, \$exon_start, \$exon_end); 


  while($sth->fetch()) {
    
    push @out, Bio::EnsEMBL::ExternalData::CDSTrack::Location->new(
              -dbID        => $dbid,
              -exon_start  => $exon_start + 1,
              -exon_end    => $exon_end + 1,
              -adaptor     => $self 
    );
  
    
  }
  return \@out;
}



1;
