#$Id: DBAdaptor.pm,v 1.24 2004-09-30 21:19:51 w3adm Exp $
#
# BioPerl module for Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor
#
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Heikki Lehvaslaiho
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor - Class for a sequence
variation database providing external features for EnsEMBL

=head1 SYNOPSIS

  use Bio::EnsEMBL::External::SNPSQL::DBAdaptor;
  $snpdb = Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor->new( -dbname => 'snp'
							  -user => 'root'
							  );


   # accessing sequence variations by id
   # $snp is a Bio::EnsEMBL::ExternalData::Variation object
   # the method call returns an array of Variation objects; 
   # one for each location
   my @snps = $snpdb->get_SNPAdaptor->fetch_by_refsnp_id("578");
   my $snp = pop @snps;


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

package Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor;

use Bio::EnsEMBL::DBSQL::DBAdaptor;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::DBSQL::DBAdaptor);

sub get_Hitcount {
    my ($self) = @_;
    my $sth=$self->prepare("select count(*) from RefSNP");
    my $res=$sth->execute();

    my ($count) = $sth->fetchrow_array();
   
    return $count;
}

sub get_max_refsnpid {
    my ($self) = @_;
    my $sth=$self->prepare("select max(id) from RefSNP");
    my $res=$sth->execute();

    my ($count) = $sth->fetchrow_array();
   
    return $count;
}

sub get_available_adaptors{
  my %pairs = ("SNP", "Bio::EnsEMBL::ExternalData::SNPSQL::SNPAdaptor");
  return (\%pairs);
}


#######################################################################
#
#  BEGIN DEPRECATED FUNCTIONS
#
#######################################################################

sub get_Ensembl_SeqFeatures_contig {
  my $self = shift;

  $self->throw("get_Ensembl_SeqFeatures_contig is deprecated\n");

  return ();
}


sub get_SeqFeature_by_id {
  my ($self, @args) = @_;

  $self->warn("get_SeqFeature_by_id is deprecated. " .
     "Use \$db_adaptor->get_SNPAdaptor()->fetch_by_SNP_id(\$id) instead\n");

  return $self->get_SNPAdaptor()->fetch_by_SNP_id(@args);
}

sub get_Ensembl_SeqFeatures_clone {
  my ($self, @args) = @_;
 
  $self->warn("get_Ensembl_SeqFetures_clone is deprecated. " .
      "Use: \$db_adaptor->get_SNPAdaptor()->fetch_by_clone_" .
      "accession_version(\$acc, \$ver) instead\n");
  
  return $self->get_SNPAdaptor()->fetch_by_clone_accession_version(@args);
}


sub get_Ensembl_SeqFeatures_clone_web {
  my ($self, @args) = @_;

  $self->warn("get_Ensembl_SeqFeatures_clone_web is deprecated. " .
       "To draw web features the Lite database should be used instead. " .
       "Try using: " .
       "\$lite_dbadaptor->get_SNPAdaptor()->fetch_by_Slice(\$slice)");
}


sub get_snp_info_between_two_internalids {
  my ($self, @args) = @_;

  $self->warn("get_snp_info_between_two_internalids is deprecated. Use: " .
     "\$db_adaptor->get_SNPAdaptor()->fetch_between_refsnpids(\$id1, \$id2)");

  return $self->get_SNPAdaptor()->fetch_between_refsnpids(@args);
}
 
  
sub get_snp_info_by_refsnpid {
  my($self, @args) = @_;
  
  $self->warn("get_snp_info_by_refsnpid is deprecated.  Use: " .
        "\$db_adaptor->get_SNPAdaptor()->fetch_by_refsnpid(\$id)");

  return $self->get_SNPAdaptor()->fetch_by_refsnpid(@args);
}

1;
