# EnsEMBL Gene reading writing adaptor for mySQL
#
# Copyright EMBL-EBI 2002
#
# Author: Heikki Lehvaslaiho
# 
# Date : 09.08.2002
#

=head1 NAME

Bio::EnsEMBL::ExternalData::CancerGenomeProject::DBSQL::LocusAdaptor

=head1 SYNOPSIS

A locus adaptor which sits over the  CancerGenomeProject database.
Provides a means of getting CancerGenomeProject::Locus objects
out of a CancerGenomeProject database as 

=head1 CONTACT

  Arne Stabenau: stabenau@ebi.ac.uk
  Graham McVicker : mcvicker@ebi.ac.uk
  James Smith : js5@sanger.ac.uk
  Roger Pettett : rmp@sanger.ac.uk

=head1 APPENDIX

=cut

use strict;

package Bio::EnsEMBL::ExternalData::CancerGenomeProject::DBSQL::LocusAdaptor;

use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::Utils::Eprof qw( eprof_start eprof_end);

use vars '@ISA';

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);



=head2 fetch_by_onco_id

 Title   : fetch_by_CancerGenomeProject_id
 Usage   : $snp_adaptor->fetch_by_snp_id($refsnp_id);
 Function:
 Example :
 Returns : a ??
 Args    : id as determined by this database


=cut

sub fetch_by_onco_id {
    my ($self, $id ) = @_;
    my $peptide;

    #lists of variations to be returned
    return $peptide;
}

1;
