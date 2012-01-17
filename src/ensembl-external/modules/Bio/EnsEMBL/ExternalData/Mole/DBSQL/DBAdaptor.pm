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

Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor

=head1 SYNOPSIS

    $db = Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor->new(
        -user   => 'root',
        -dbname => 'pog',
        -host   => 'caldy',
        -driver => 'mysql',
        );


=head1 DESCRIPTION

This object represents the handle for a Kill-List database

=head1 CONTACT

Post questions the the EnsEMBL developer list: <ensembl-dev@ebi.ac.uk>

=cut


# Let the code begin...


package Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBAdaptor;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::DBSQL::DBAdaptor;

@ISA = qw( Bio::EnsEMBL::DBSQL::DBAdaptor );

sub get_available_adaptors {
 
  my %pairs =  (
      "Accession"     => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::AccessionAdaptor",
      "BlackList"     => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::BlackListAdaptor",
      "DBXref"        => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::DBXrefAdaptor",
      "Comment"       => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::CommentAdaptor",
      "Description"   => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::DescriptionAdaptor",
      "Entry"         => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::EntryAdaptor",
      "EntryArchive"  => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::EntryArchiveAdaptor",
      "GeneName"      => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::GeneNameAdaptor",
      "Keyword"       => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::KeywordAdaptor",
      "Location"      => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::LocationAdaptor",
      "Sequence"      => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::SequenceAdaptor",
      "Taxonomy"      => "Bio::EnsEMBL::ExternalData::Mole::DBSQL::TaxonomyAdaptor",
        );
  return (\%pairs);
}
 

1;
