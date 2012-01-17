#$Id: DBAdaptor.pm,v 1.1 2002-10-14 13:32:26 w3adm Exp $
#
=head1 NAME

Bio::EnsEMBL::ExternalData::CancerGenomeProject::DBSQL::DBAdaptor - Class for a sequence
variation database providing external features for EnsEMBL

=head1 SYNOPSIS


    $oncodb = Bio::EnsEMBL::ExternalData::CancerGenomeProject::DBSQL::DBAdaptor->new( -dbname => 'onco'
							  -user => 'root'
							  );


   # accessing sequence variations by id
   # $onco is a Bio::EnsEMBL::ExternalData::Variation object
   # the method call returns an array of Variation objects; 
   # one for each location
   my @oncos = $oncodb->get_LocusAdaptor->fetch_by_refonco_id("578");
   my $onco = pop @oncos;


=head1 DESCRIPTION

This object is an abstraction over the EnsEMBL SNP database.  Adaptors can
be obtained for the database to allow for the storage or retrival of objects
stored within the database.


=head1 FEEDBACK

=head2 Mailing Lists

  User feedback is an integral part of the evolution of this
  and other Ensebl modules. Send your comments and suggestions preferably
  to one of the Bioperl mailing lists.
  Your participation is much appreciated.

  vsns-bcd-perl@lists.uni-bielefeld.de          - General discussion
  vsns-bcd-perl-guts@lists.uni-bielefeld.de     - Technically-oriented discussion
  http://bio.perl.org/MailList.html             - About the mailing lists

=head2 Reporting Bugs

  Report bugs to the Bioperl bug tracking system to help us keep track
  the bugs and their resolution.
  Bug reports can be submitted via email or the web:

  ensembl-dev@ebi.ac.uk                        - General discussion

=head1 AUTHOR - Heikki Lehvaslaiho

  Email heikki@ebi.ac.uk

Address:

     EMBL Outstation, European Bioinformatics Institute
     Wellcome Trust Genome Campus, Hinxton
     Cambs. CB10 1SD, United Kingdom

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::EnsEMBL::ExternalData::CancerGenomeProject::DBSQL::DBAdaptor;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::DBSQL::DBConnection);

#use the DBConnection superclass constructor

=head2 get_LocusAdaptor

  Function  : Retrieves a LocusAdaptor from this database
  Returntype: Bio::EnsEMBL::ExternalData::CancerGenomeProject::DBSQL::LocusAdaptor
  Exceptions: none
  Caller    : perl/default/oncoview  Bio::EnsEMBL::DBSQL::ProxyLocusAdaptor

=cut

sub get_LocusAdaptor {
  my $self = shift;

  return $self->_get_adaptor("Bio::EnsEMBL::ExternalData::CancerGenomeProject::DBSQL::LocusAdaptor");
}

1;
