# 
# BioPerl module for Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor
# 
# Cared for by Tony Cox <avc@sanger.ac.uk>
#
# Copyright EnsEMBL
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

GlovarAdaptor - DESCRIPTION of Object

  This object represents the Glovar database.

=head1 SYNOPSIS

$glodb = Bio::EnsEMBL::ExternalData::Glovar::DBAdaptor->new(
                                         -user   => 'ensro',
                                         -dbname => 'snp',
                                         -host   => 'go_host',
                                         -driver => 'Oracle');

my $glovar_adaptor = $glodb->get_GlovarAdaptor;

$var_listref  = $glovar_adaptor->fetch_all_by_Slice($slice);  # grab the lot!


=head1 DESCRIPTION

This module is an entry point into a glovar database,

Objects can only be read from the database, not written. (They are
loaded using a separate system).

=head1 CONTACT

 Tony Cox <avc@sanger.ac.uk>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor;
use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::External::ExternalFeatureAdaptor;
use Bio::EnsEMBL::SeqFeature;
use Bio::EnsEMBL::SNP;
use Bio::Annotation::DBLink;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor Bio::EnsEMBL::External::ExternalFeatureAdaptor);

=head2 fetch_clone_by_accession

  Arg[1]      : String $embl_acc - EMBL accession of the clone
  Example     : my ($nt_name, $id_seq, $clone_start, $clone_end, $clone_strand) = $glovar_adaptor->fetch_clone_by_accession('AL123456');
  Description : Fetches clone info from Glovar by accession
  Return type : List of
                    sequence name the clone is mapped to
                    dbID of this sequence
                    start coordinate of clone mapping
                    end coordinate of clone mapping
                    strand of clone mapping
  Exceptions  : thrown if data fetching error occurs
  Caller      : usually subclasses of GlovarAdaptor

=cut

sub fetch_clone_by_accession {
    my ($self, $embl_acc) = @_;

    # get info on clone
    my $q1 = qq(
        SELECT
                ss.database_seqnname,
                csm.id_sequence,
                csm.start_coordinate,
                csm.end_coordinate,
                csm.contig_orientation,
                ss.database_source,
                ss.is_current
        FROM    clone_seq cs,
                clone_seq_map csm,
                snp_sequence ss
        WHERE   cs.database_seqname = '$embl_acc'
        AND     cs.id_cloneseq = csm.id_cloneseq
        AND     csm.id_sequence = ss.id_sequence
        AND     ss.is_current = 1
    );
    my $sth;
    eval {
        $sth = $self->prepare($q1);
        $sth->execute();
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return();
    }
    my ($nt_name, $id_seq, $clone_start, $clone_end, $clone_strand);
    my @cloneinfo;
    my %stats = map { $_ => 0 } qw(NT clone);
    while (my @res = $sth->fetchrow_array) {
        if ($res[0] =~ /NT_/) {
            $stats{'NT'}++;
        } else {
            $stats{'clone'}++;
        }
        @cloneinfo = @res;
    }
    if (($stats{'NT'} + $stats{'clone'}) > 1) {
        warning("Clone ($embl_acc) maps to more than one NTs ($stats{NT}) and/or clones ($stats{clones}).");
    }

    # return result list
    return (@cloneinfo);
}

sub track_name {
    my ($self) = @_;    
    die("ERROR: track_name called on Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor!\n
        It should be implemented by a derived class!\n");
}

1;
