=head1 NAME

Bio::EnsEMBL::ExternalData::Glovar::GlovarSTSAdaptor -
Database adaptor for Glovar STSs

=head1 SYNOPSIS

$glodb = Bio::EnsEMBL::ExternalData::Glovar::DBAdaptor->new(
                                         -user   => 'ensro',
                                         -pass   => 'secret',
                                         -dbname => 'snp',
                                         -host   => 'go_host',
                                         -driver => 'Oracle'
);
my $glovar_adaptor = $glodb->get_GlovarSTSAdaptor;
$var_listref  = $glovar_adaptor->fetch_all_by_clone_accession(
                    'AL100005', 'AL100005', 1, 10000);

=head1 DESCRIPTION

This module is an entry point into a Glovar database. It allows you to retrieve
STSs from Glovar.

=head1 AUTHOR

Tony Cox <avc@sanger.ac.uk>
Patrick Meidl <pm2@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

package Bio::EnsEMBL::ExternalData::Glovar::GlovarSTSAdaptor;

use strict;

use Bio::EnsEMBL::ExternalData::Glovar::STS;
use Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor;

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor);


=head2 fetch_all_by_clone_accession

  Arg[1]      : clone internal ID
  Arg[2]      : clone embl accession
  Arg[3]      : clone start coordinate
  Arg[4]      : clone end coordinate
  Example     : @list = @{$glovar_adaptor->fetch_all_by_clone_accession(
                    'AL100005', 'AL100005', 1, 10000)};
  Description: Retrieves STSs on a clone in clone coordinates.
  Returntype : Listref of Bio::EnsEMBL::ExternalData::Glovar::STS objects
  Exceptions : none
  Caller     : $self->fetch_all_by_Clone

=cut

sub fetch_all_by_clone_accession {
    my ($self, $embl_acc, $embl_version, $cl_start, $cl_end) = @_;

    # get info on clone
    my @cloneinfo = $self->fetch_clone_by_accession($embl_acc);
    return([]) unless (@cloneinfo);
    my ($nt_name, $id_seq, $clone_start, $clone_end, $clone_strand) = @cloneinfo;

    # now get the STSs on this clone
    # get only features in the desired region of the clone
    my ($q_start, $q_end);
    if ($clone_strand == 1) {
        $q_start = $clone_start + $cl_start - 1;
        $q_end = $clone_start + $cl_end + 1;
    } else{
        $q_start = $clone_end - $cl_end - 1;
        $q_end = $clone_end - $cl_start + 1;
    }
    # also get STS which don't start within the clone region, but overlap it
    # (assumes a max STS length of 1000 bp)
    $q_start -= 1000;
    
    # NOTE:
    # This query only gets ExoSeq STSs (sts_summary.assay_type = 8).
    my $q2 = qq(
        SELECT 
                ss.id_sts                           as internal_id,
                ss.sts_name                         as sts_name,
                ms.start_coordinate                 as sts_start,
                ms.end_coordinate                   as sts_end,
                ms.is_revcomp                       as sts_strand,
                length(ss.sense_oligoprimer)        as sen_len,
                length(ss.antisense_oligoprimer)    as anti_len,
                sod.description                     as pass_status,
                sad.description                     as assay_type,
                ss.is_private                       as private
        FROM    
                mapped_sts ms,
                sts_summary ss,
                sts_outcome_dict sod,
                snpassaydict sad
        WHERE   ms.id_sequence = ?
        AND     ms.id_sts = ss.id_sts
        AND     ss.assay_type = sad.id_dict
        AND     ss.pass_status = sod.id_dict
        AND     ms.start_coordinate BETWEEN $q_start AND $q_end
    );
    
    my $sth;
    eval {
        $sth = $self->prepare($q2);
        $sth->execute($id_seq);
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return([]);
    }

    my @features = ();
    while (my $row = $sth->fetchrow_hashref()) {
        return([]) unless keys %{$row};
        warn "WARNING: private STS!" if $row->{'PRIVATE'};

        ## calculate coords depending on clone orientation
        my ($start, $end);
        $row->{'STS_END'} ||= $row->{'STS_START'};
        if ($clone_strand == 1) {
            $start = $row->{'STS_START'} - $clone_start + 1;
            $end = $row->{'STS_END'} - $clone_start + 1;
        } else {
            $start = $clone_end - $row->{'STS_END'} + 1;
            $end = $clone_end - $row->{'STS_START'} + 1;
        }
        my $strand = (1 - 2 * $row->{'STS_STRAND'}) * $clone_strand;

        # the following lines correct for an off by one error in mapped_sts
        # 1 should be substracted from all coords once db has been fixed
        
        push @features, Bio::EnsEMBL::ExternalData::Glovar::STS->new_fast({
                'analysis'          =>  'glovar_sts',
                'display_id'        =>  $row->{'STS_NAME'},
                'dbID'              =>  $row->{'INTERNAL_ID'},
                'start'             =>  $start,
                'end'               =>  $end,
                'strand'            =>  $strand,
                'seqname'           =>  $embl_acc,
                'sense_length'      =>  $row->{'SEN_LEN'},
                'antisense_length'  =>  $row->{'ANTI_LEN'},
                'pass_status'       =>  $row->{'PASS_STATUS'},
                'assay_type'        =>  $row->{'ASSAY_TYPE'},
        });
    }
    
    return(\@features);
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
  Example     : my $track_name = $sts_adaptor->track_name;
  Description : returns the track name
  Return type : String - track name
  Exceptions  : none
  Caller      : Bio::EnsEMBL::Slice,
                Bio::EnsEMBL::ExternalData::ExternalFeatureAdaptor

=cut

sub track_name {
    my ($self) = @_;    
    return("GlovarSTS");
}

1;

