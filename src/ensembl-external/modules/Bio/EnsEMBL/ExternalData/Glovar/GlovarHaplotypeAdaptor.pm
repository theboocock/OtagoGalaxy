=head1 NAME

GlovarHaplotypeAdaptor -
Database adaptor for Glovar haplotypes

=head1 SYNOPSIS

$glodb = Bio::EnsEMBL::ExternalData::Glovar::DBAdaptor->new(
                                         -user   => 'ensro',
                                         -pass   => 'secret',
                                         -dbname => 'snp',
                                         -host   => 'go_host',
                                         -driver => 'Oracle');
my $glovar_adaptor = $glodb->get_GlovarHaplotypeAdaptor;
$var_listref  = $glovar_adaptor->fetch_all_by_clone_accession(
                    'AL100005', 'AL100005', 1, 10000);

=head1 DESCRIPTION

This module is an entry point into a Glovar database. It allows you to retrieve
haplotype data from the database.

=head1 AUTHOR

Patrick Meidl <pm2@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

package Bio::EnsEMBL::ExternalData::Glovar::GlovarHaplotypeAdaptor;

use strict;

use Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor;
use Bio::EnsEMBL::ExternalData::Glovar::Haplotype;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);
use Bio::EnsEMBL::Registry;

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor);


=head2 fetch_all_by_clone_accession

  Arg[1]      : clone internal ID
  Arg[2]      : clone embl accession
  Arg[3]      : clone start coordinate
  Arg[4]      : clone end coordinate
  Example     : @list = @{$glovar_adaptor->fetch_all_by_clone_accession(
                    'AL100005', 'AL100005', 1, 10000)};
  Description: Retrieves haplotypes (blocks of SNPs) on a clone in clone
               coordinates. Since Glovar stores now haplotype start/end data,
               the haplotypes have to be retrieved in a two-step process:
               1. get IDs of all haplotypes in the requested region
               2. for all these IDs, get tagSNPs assigned to them
               Haplotype start/end have to be inferred from the tagSNP
               coordinates.
  Returntype : Listref of Bio::EnsEMBL::ExternalData::Glovar::Haplotype objects
  Exceptions : none
  Caller     : $self->fetch_all_by_Clone

=cut

sub fetch_all_by_clone_accession {
    my ($self, $embl_acc, $embl_version, $cl_start, $cl_end) = @_;

    my $dnadb = Bio::EnsEMBL::Registry->get_DNAAdaptor($ENV{'ENSEMBL_SPECIES'}, 'glovar');
    unless ($dnadb) {
        warning("ERROR: No dnadb attached to Glovar.\n");
        return([]);
    }
    
    # get info on clone
    my @cloneinfo = $self->fetch_clone_by_accession($embl_acc);
    return([]) unless (@cloneinfo);
    my ($nt_name, $id_seq, $clone_start, $clone_end, $clone_strand) = @cloneinfo;

    # get only features in the desired region of the clone
    my ($q_start, $q_end);
    if ($clone_strand == 1) {
        $q_start = $clone_start + $cl_start - 1;
        $q_end = $clone_start + $cl_end + 1;
    } else{
        $q_start = $clone_end - $cl_end - 1;
        $q_end = $clone_end - $cl_start + 1;
    }
    my $clone_length = $clone_end - $clone_start + 1;
    
    # get all haplotype blocks
    my $q2 = qq(
        SELECT
                sb.id_block             as block,
                ss.is_private           as private_snp,
                bs.is_private           as private_block
        FROM    
                mapped_snp ms,
                snp_summary ss,
                snp_block sb,
                block b,
                block_set bs
        WHERE   ms.id_sequence = ?
        AND     ms.id_snp = ss.id_snp
        AND     ss.id_snp = sb.id_snp
        AND     sb.id_block = b.id_block
        AND     b.id_block_set = bs.id_block_set
        AND     ms.position BETWEEN $q_start AND $q_end
    );

    my $sth;
    eval {
        $sth = $self->prepare($q2);
        $sth->execute($id_seq);
    }; 
    if ($@){
        warning("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return([]);
    }

    my @blocks;
    while (my $b = $sth->fetchrow_hashref()) {
        return([]) unless keys %{$b};
        warning("WARNING: private haplotype/SNP!") if ($b->{'PRIVATE_SNP'} ||
                                                   $b->{'PRIVATE_BLOCK'});

        push @blocks, $b->{'BLOCK'};
    }
    return([]) unless (@blocks);
    my $blocklist = join(",", @blocks);

    # now get all tagSNPs for the haplotypes found
    my $q3 = qq(
        SELECT
                ms.position             as snp_start,
                ms.end_position         as snp_end,
                ms.is_revcomp           as snp_strand,
                sb.id_block             as internal_id,
                b.name                  as block_name,
                b.length                as block_length,
                b.num_snps              as num_snps,
                p.description           as population,
                ss.is_private           as private_snp,
                bs.is_private           as private_block
        FROM    
                mapped_snp ms,
                snp_summary ss,
                snp_block sb,
                block b,
                block_set bs,
                population p
        WHERE   ms.id_sequence = ?
        AND     sb.id_block IN ($blocklist)
        AND     ms.id_snp = ss.id_snp
        AND     ss.id_snp = sb.id_snp
        AND     sb.id_block = b.id_block
        AND     b.id_block_set = bs.id_block_set
        AND     bs.id_pop = p.id_pop
    );

    eval {
        $sth = $self->prepare($q3);
        $sth->execute($id_seq);
    }; 
    if ($@){
        warning("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return([]);
    }

    # get a clone slice and projectc it to chromosomal coordinates
    # this is needed for tag SNP and haplotype coordinate calculations
    my $clone = $dnadb->get_SliceAdaptor->fetch_by_region('clone', $embl_acc);
    my $projected_clone = $clone->project('chromosome');
    unless ($projected_clone) {
        warning("Clone $embl_acc doesn't project to chromosome.");
        return([]);
    }

    my $haplotypes;
    while (my $row = $sth->fetchrow_hashref()) {
        return([]) unless keys %{$row};
        warn "WARNING: private haplotype/SNP!" if ($row->{'PRIVATE_SNP'} ||
                                                   $row->{'PRIVATE_BLOCK'});

        ## filter SNPs without strand (this is gruft in mapped_snp)
        next unless $row->{'SNP_STRAND'};

        ## calculate clone coords depending on clone orientation
        my ($start, $end);
        $row->{'SNP_END'} ||= $row->{'SNP_START'};
        if ($clone_strand == 1) {
            $start = $row->{'SNP_START'} - $clone_start + 1;
            $end = $row->{'SNP_END'} - $clone_start + 1;
        } else {
            $start = $clone_end - $row->{'SNP_END'} + 1;
            $end = $clone_end - $row->{'SNP_START'} + 1;
        }
        my $strand = $row->{'SNP_STRAND'}*$clone_strand;

        # create a haplotype object if it doesn't already exist
        $haplotypes->{$row->{'INTERNAL_ID'}} ||=
                Bio::EnsEMBL::ExternalData::Glovar::Haplotype->new_fast({
                    'analysis'      => 'glovar_haplotype',
                    'display_id'    => $row->{'BLOCK_NAME'},
                    'dbID'          => $row->{'INTERNAL_ID'},
                    'start'         => $start,
                    'end'           => $end,
                    'strand'        => $clone_strand,
                    'seqname'       => $embl_acc,
                    'population'    => $row->{'POPULATION'},
                    'num_snps'      => $row->{'NUM_SNPS'},
                });
        my $hap = $haplotypes->{$row->{'INTERNAL_ID'}};

        # record haplotype start/end, ie max(snp_start)/max(snp_end)
        $hap->start($start) if ($hap->start > $start);
        $hap->end($end) if ($hap->end < $end);

        # calculate SNP chromosomal coords
        my $snp = Bio::EnsEMBL::Feature->new(
                    -SLICE  => $clone,
                    -START  => $start,
                    -END    => $end,
                    -STRAND => $strand,
        );
        $snp = $snp->transform('chromosome');
        # skip SNPs that don't transform
        next unless $snp;
        
        # push tag SNP coords on haplotype
        $hap->add_tagSNP($snp->start, $snp->end);
    }
    
    # return listref of haplotype objects
    my @haps = ();
    foreach my $key (keys %$haplotypes) {
        # trim haplotype to golden portion of clone (otherwise it will be 
        # discarded during the mapping to chromosome)
        if ($haplotypes->{$key}->start < $projected_clone->[0]->from_start) {
            $haplotypes->{$key}->start($projected_clone->[0]->from_start);
        }
        if ($haplotypes->{$key}->end > $projected_clone->[0]->from_end) {
            $haplotypes->{$key}->end($projected_clone->[0]->from_end);
        }
        push @haps, $haplotypes->{$key};
    }
    return \@haps;
}                                       

=head2 coordinate_systems

  Arg[1]      : none
  Example     : my @coord_systems = $glovar_adaptor->coordinate_systems;
  Description : This method returns a list of coordinate systems which are
                implemented by this class. A minimum of one valid coordinate
                system must be implemented. Valid coordinate systems are:
                'SLICE', 'ASSEMBLY', 'CONTIG', and 'CLONE'.
  Return type : list of strings
  Exceptions  : none
  Caller      : internal

=cut

sub coordinate_systems {
    return ('CLONE');
}

=head2 track_name

  Arg[1]      : none
  Example     : my $track_name = $haplotype_adaptor->track_name;
  Description : returns the track name
  Return type : String - track name
  Exceptions  : none
  Caller      : Bio::EnsEMBL::Slice,
                Bio::EnsEMBL::ExternalData::ExternalFeatureAdaptor

=cut

sub track_name {
    my ($self) = @_;    
    return("GlovarHaplotype");
}

1;
