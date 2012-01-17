=head1 NAME

Bio::EnsEMBL::ExternalData::Glovar::GlovarTraceAdaptor -
Database adaptor for Glovar traces

=head1 SYNOPSIS

$glodb = Bio::EnsEMBL::ExternalData::Glovar::DBAdaptor->new(
                                         -user   => 'ensro',
                                         -pass   => 'secret',
                                         -dbname => 'snp',
                                         -host   => 'go_host',
                                         -driver => 'Oracle');
my $glovar_adaptor = $glodb->get_GlovarTraceAdaptor;
$listref  = $glovar_adaptor->fetch_all_by_Slice($slice);

=head1 DESCRIPTION

This module is an entry point into a glovar database. It allows you to retrieve
traces from Glovar

=head1 AUTHOR

Patrick Meidl <pm2@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

package Bio::EnsEMBL::ExternalData::Glovar::GlovarTraceAdaptor;

use strict;

use Bio::EnsEMBL::MapFrag;
use Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor;
use Bio::EnsEMBL::Utils::Eprof('eprof_start','eprof_end','eprof_dump');

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor);


=head2 fetch_all_by_Slice

  Arg [1]    : Bio::EnsEMBL::Slice
  Arg [2]    : (optional) boolean $is_lite
               Flag indicating if 'light weight' variations should be obtained
  Example    : @list = @{$glovar_adaptor->fetch_all_by_Slice($slice)};
  Description: Retrieves a list of traces on a slice in chromosomal coordinates 
  Returntype : Listref of Bio::EnsEMBL::MapFrag objects
  Exceptions : none
  Caller     : Bio::EnsEMBL::Slice::get_all_ExternalFeatures

=cut

sub fetch_all_by_Slice {
    my ($self, $slice, $is_light) = @_;

    unless ($slice->assembly_name && $slice->assembly_version) {
        warn ("Cannot determine assembly name and version from Slice in GlovarAdaptor!\n");
        return ([]);
    }

    my @f = ();
    if($is_light){
        push @f, @{$self->fetch_Light_Trace_by_chr_start_end($slice)};
    } else {
        push @f, @{$self->fetch_Trace_by_chr_start_end($slice)};
    } 
    return(\@f); 
}


=head2 fetch_Light_Trace_by_chr_start_end

  Arg [1]    : Bio::EnsEMBL::Slice
  Example    : @list = @{$glovar_adaptor->fetch_Light_Trace_by_chr_start_end($slice)};
  Description: Retrieves a list of traces on a slice in chromosomal coordinates.
               Returns lightweight objects for drawing purposes.
  Returntype : Listref of Bio::EnsEMBL::MapFrag objects
  Exceptions : none
  Caller     : $self->fetch_all_by_slice

=cut

sub fetch_Light_Trace_by_chr_start_end  {
    my ($self,$slice) = @_; 
    my $slice_chr    = $slice->chr_name();
    my $slice_start  = $slice->chr_start();
    my $slice_end    = $slice->chr_end();
    my $ass_name     = $slice->assembly_name();
    my $ass_version  = $slice->assembly_version();

    ## return traces from cache if available
    my $key = join(":", $slice_chr, $slice_start, $slice_end);
    if ($self->{'_cache'}->{$key}) {
        return $self->{'_cache'}->{$key};
    }

    &eprof_start('glovar_trace2');

    ## NOTE:
    ## all code here assumes that ssm.contig_orientation is always 1!

    my $q = qq(
        SELECT   
                ms.snp_rea_id_read      as read_id,
                sr.readname             as readname,
                ms.contig_match_start   as contig_start,
                ms.contig_match_end     as contig_end,
                ms.contig_orientation   as read_ori,
                ms.read_match_start     as read_start,
                ms.read_match_end       as read_end,
                ssm.start_coordinate    as chr_start,
                ssm.end_coordinate      as chr_end,
                ssm.contig_orientation  as contig_ori
        FROM    chrom_seq cs,
                seq_seq_map ssm,
                mapped_seq ms,
                snp_read sr,
                database_dict dd
        WHERE   cs.database_seqname = '$slice_chr'
        AND     dd.database_version = '$ass_version'
        AND     dd.database_name = '$ass_name'
        AND     cs.database_source = dd.id_dict
        AND     cs.id_chromseq = ssm.id_chromseq
        AND     ssm.sub_sequence = ms.id_sequence
        AND     ms.snp_rea_id_read = sr.id_read
        AND     ssm.start_coordinate
                BETWEEN
                ($slice_start - ms.contig_match_end + 1)
            AND
                ($slice_end - ms.contig_match_start + 1)
    );

    my $sth;
    eval {
        $sth = $self->prepare($q);
        $sth->execute();
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return([]);
    }

    my @traces = ();
    while (my $row = $sth->fetchrow_hashref()) {
        return([]) unless keys %{$row};
        #next if $row->{'PRIVATE'};
        
        ## NT_contigs should always be on forward strand
        warn "Contig is in reverse orientation. THIS IS BAD!"
            if ($row->{'CONTIG_ORI'} == -1);
        
        my $start = $row->{'CONTIG_START'} + $row->{'CHR_START'} - 1;
        my $end = $row->{'CONTIG_END'} + $row->{'CHR_START'} - 1;
        my $strand = $row->{'READ_ORI'};
        
        my $trace = Bio::EnsEMBL::MapFrag->new(
            $slice_start,
            $row->{'READ_ID'},
            'clone',
            $slice_chr,
            'Chromosome',
            $start,
            $end,
            $strand,
            $row->{'READNAME'},
        );
        
        $trace->add_annotation('read_start', $row->{'READ_START'});
        $trace->add_annotation('read_end', $row->{'READ_END'});
        
        ## add strand as annotation so that GlyphSet_simple understands it
        $trace->add_annotation('strand', $strand);

        #warn join(" | ", $row->{'READNAME'}, $start, $end, $strand);

        push (@traces, $trace); 
    }
    
    ## sort the traces by start chromosomal coordinate
    @{$self->{'_cache'}->{$key}} = 
        sort { $a->seq_start <=> $b->seq_start }
            @traces;
    
    &eprof_end('glovar_trace2');
    
    return $self->{'_cache'}->{$key};
}                                       

=head2 fetch_Trace_by_chr_start_end

  Arg [1]    : Bio::EnsEMBL::Slice
  Example    : @list = @{$glovar_adaptor->fetch_Trace_by_chr_start_end($slice)};
  Description: Retrieves a list of traces on a slice in chromosomal coordinates.
  Returntype : Listref of Bio::EnsEMBL::MapFrag objects
  Exceptions : none
  Caller     : $self->fetch_all_by_slice

=cut

sub fetch_Trace_by_chr_start_end  {
    my ($self, $slice) = @_;

    ## to be implemented
    
    return(1);
}

=head2 fetch_Trace_by_id

  Arg[1]      : String - trace ID
  Example     : my $trace = $glovar_adaptor->fetch_Trace_by_id($id);
  Description : retrieve traces from Glovar by ID
  Return type : Listref of Bio::EnsEMBL::MapFrag objects
  Exceptions  : none
  Caller      : $self

=cut

sub fetch_Trace_by_id  {
    my ($self, $id) = @_;
    return(1);
}

=head2 track_name

  Arg[1]      : none
  Example     : my $track_name = $trace_adaptor->track_name;
  Description : returns the track name
  Return type : String - track name
  Exceptions  : none
  Caller      : Bio::EnsEMBL::Slice,
                Bio::EnsEMBL::ExternalData::ExternalFeatureAdaptor

=cut

sub track_name {
    my ($self) = @_;    
    return("GlovarTrace");
}

1;

