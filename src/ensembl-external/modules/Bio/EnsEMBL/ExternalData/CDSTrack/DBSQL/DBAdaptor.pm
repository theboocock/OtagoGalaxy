#
# BioPerl module for DBSQL::Obj
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor

=head1 SYNOPSIS

    $db = Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor->new(
        -user   => 'root',
        -dbname => 'pog',
        -host   => 'caldy',
        -driver => 'mysql',
        );


=head1 DESCRIPTION

This object represents the handle for a CDSTrack database

=head1 CONTACT

Post questions the the EnsEMBL developer list: <ensembl-dev@ebi.ac.uk>

=cut




package Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::DBAdaptor;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::DBSQL::DBAdaptor;

@ISA = qw( Bio::EnsEMBL::DBSQL::DBAdaptor );

warn("\n\nUsing ExternalData::CDSTrack DBAdaptor\n\n");


sub get_available_adaptors {
 
  print "Getting available adaptors\n";
  my %pairs =  (
      "Accession"                         => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::AccessionAdaptor",
      "CcdsStatus"                        => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::CcdsStatusAdaptor",
      "Ccds"                              => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::CcdsAdaptor",
      "GroupVersion"                      => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::GroupVersionAdaptor",
      "Group"                             => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::GroupAdaptor",
      "Interpretation"                    => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::InterpretationAdaptor",
      "Location"                          => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::LocationAdaptor",
      "Organization"                      => "Bio::EnsEMBL::ExternalData::CDSTrack::DBSQL::OrganizationAdaptor",
  );
  return (\%pairs);
}
 

1;
