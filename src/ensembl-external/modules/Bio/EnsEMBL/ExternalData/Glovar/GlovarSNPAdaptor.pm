=head1 NAME

Bio::EnsEMBL::ExternalData::Glovar::GlovarSNPAdaptor -
Object adaptor for Glovar SNPs

=head1 SYNOPSIS

$glodb = Bio::EnsEMBL::ExternalData::Glovar::DBAdaptor->new(
                                         -user   => 'ensro',
                                         -pass   => 'secret',
                                         -dbname => 'snp',
                                         -host   => 'go_host',
                                         -driver => 'Oracle'
);
my $glovar_adaptor = $glodb->get_GlovarSNPAdaptor;
my $snps = $glovar_adaptor->fetch_all_by_clone_accession('AL100005', 'AL100005', 1, 10000);

=head1 DESCRIPTION

This module is an entry point into a glovar database. It allows you to retrieve
SNPs from Glovar.

=head1 AUTHORS

Tony Cox <avc@sanger.ac.uk>
Patrick Meidl <pm2@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

package Bio::EnsEMBL::ExternalData::Glovar::GlovarSNPAdaptor;

use strict;

use Bio::EnsEMBL::Variation::VariationFeature;
use Bio::EnsEMBL::Variation::Variation;
use Bio::EnsEMBL::Variation::TranscriptVariation;
use Bio::EnsEMBL::Variation::PopulationGenotype;
use Bio::EnsEMBL::Variation::Population;
use Bio::EnsEMBL::Variation::Allele;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end eprof_dump);
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor);

# map Glovar validation states to Ensembl ones
our %VSTATE_MAP = (
        'Observed'          => 'observed',
        'Sanger Verified'   => 'submitter',
        'Verified'          => 'submitter',
        'Two-hit'           => 'doublehit',
        'Non-polymorphic'   => 'non-polymorphic',
        'HapMap Verified'   => 'hapmap',
);

# map Glovar consequence and position type to Ensembl consequence type
our %CONSEQUENCE_TYPE_MAP = (
        'Coding Synonymous'             => 'SYNONYMOUS_CODING',
        'Coding Non-synonymous'         => 'NON_SYNONYMOUS_CODING',
        'Coding Sop gained'             => 'STOP_GAINED',
        'Coding Stop lost'              => 'STOP_LOST',
        'Non-coding exonic Non-coding'  => 'UTR',
        'Intronic Non-coding'           => 'INTRONIC',
        'Upstream Non-coding'           => 'UPSTREAM',
);

=head2 fetch_all_by_clone_accession

  Arg[1]      : clone internal ID
  Arg[2]      : clone embl accession
  Arg[3]      : clone start coordinate
  Arg[4]      : clone end coordinate
  Example    : @list = @{$glovar_adaptor->fetch_all_by_clone_accession('AL100005', 'AL100005', 1, 10000)};
  Description: Retrieves a list of SNPs on a clone in clone coordinates.
  Returntype : Listref of Bio::EnsEMBL::Variation::VariationFeature objects
  Exceptions : none
  Caller     : $self->fetch_all_by_Clone

=cut

sub fetch_all_by_clone_accession {
    my ($self, $embl_acc, $embl_version, $cl_start, $cl_end) = @_;

    #&eprof_start('clone_sql');
    
    # get info on clone
    my @cloneinfo = $self->fetch_clone_by_accession($embl_acc);
    return([]) unless (@cloneinfo);
    my ($nt_name, $id_seq, $clone_start, $clone_end, $clone_strand) = @cloneinfo;

    ## temporary hack for SNP density script: skip vega-specific clones
    #unless ($nt_name =~ /^NT/) {
    #    warn "WARNING: Skipping vega-specific clone ($embl_acc).\n";
    #    return ([]);
    #}

    # now get the SNPs on this clone
    # get only features in the desired region of the clone
    my ($q_start, $q_end);
    if ($clone_strand == 1) {
        $q_start = $clone_start + $cl_start - 1;
        $q_end = $clone_start + $cl_end + 1;
    } else{
        $q_start = $clone_end - $cl_end - 1;
        $q_end = $clone_end - $cl_start + 1;
    }
    my $q2 = qq(
        SELECT
                distinct(sgc.id_snp)    as id_snp,
                ss.id_snp               as internal_id,
                ss.default_name         as id_default,
                ms.position             as snp_start,
                ms.end_position         as snp_end,
                ms.is_revcomp           as snp_strand,
                scd.description         as validated,
                ss.alleles              as alleles,
                svd.description         as snpclass,
                ss.is_private           as private,
                ptd.description         as pos_type,
                cs.design_entry         as expt_id,
                sgc_dict.description    as consequence
        FROM    
                mapped_snp ms,
                snp,
                snpvartypedict svd,
                snp_confirmation_dict scd,
                snp_summary ss
        LEFT JOIN (
                snp_gene_consequence sgc
                INNER JOIN
                    coding_sequence cs on sgc.id_codingseq = cs.id_codingseq
                    AND cs.design_entry = ?
                INNER JOIN
                    sgc_dict on sgc.consequence = sgc_dict.id_dict
                ) on sgc.id_snp = ss.id_snp
        LEFT JOIN
                position_type_dict ptd on sgc.position_description = ptd.id_dict
        WHERE   ms.id_sequence = ?
        AND     ms.id_snp = ss.id_snp
        AND     ss.id_snp = snp.id_snp
        AND     snp.var_type = svd.id_dict
        AND     ss.confirmation_status = scd.id_dict
        AND     ms.position BETWEEN $q_start AND $q_end
    );

    my $sth;
    eval {
        $sth = $self->prepare($q2);
        $sth->execute($self->consequence_exp, $id_seq);
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return([]);
    }

    my (%varfeats, %cons);
    while (my $row = $sth->fetchrow_hashref()) {
        return([]) unless keys %{$row};
        warn "WARNING: private data!" if $row->{'PRIVATE'};

        ## filter SNPs without strand (this is gruft in mapped_snp)
        next unless $row->{'SNP_STRAND'};

        ## calculate coords depending on clone orientation
        my ($start, $end);
        $row->{'SNP_END'} ||= $row->{'SNP_START'};
        if ($clone_strand == 1) {
            $start = $row->{'SNP_START'} - $clone_start + 1;
            $end = $row->{'SNP_END'} - $clone_start + 1;
        } else {
            $start = $clone_end - $row->{'SNP_END'} + 1;
            $end = $clone_end -$row->{'SNP_START'} + 1;
        }

        my $strand = $row->{'SNP_STRAND'}*$clone_strand;
        my $key = join(":", $row->{'ID_DEFAULT'}, $start, $end, $strand);
        my $consequence_type = $CONSEQUENCE_TYPE_MAP{$row->{'POS_TYPE'}." ".$row->{'CONSEQUENCE'}} || '_';
        my $cons_rank = $Bio::EnsEMBL::Variation::VariationFeature::CONSEQUENCE_TYPES{uc($consequence_type)} || 99;

        if ((!$cons{$key}) or ($cons_rank < $cons{$key})) {
            # VariationFeature
            my $varfeat = Bio::EnsEMBL::Variation::VariationFeature->new_fast(
                {
                    'dbID'              => $row->{'INTERNAL_ID'},
                    'adaptor'           => $self,
                    'variation_name'    => $row->{'ID_DEFAULT'},
                    'start'             => $start,
                    'end'               => $end,
                    'strand'            => $strand,
                    'allele_string'     => $row->{'ALLELES'},
                    'source'            => 'Glovar',
                    'validation_code'   => [ $VSTATE_MAP{$row->{'VALIDATED'}} ],
                    'consequence_type'  => [ $consequence_type ],
                });

            # add minimal Variation object (needed for DBLinks)
            my $var = Bio::EnsEMBL::Variation::Variation->new(
                    -dbID               => $row->{'INTERNAL_ID'},
                    -ADAPTOR            => $self,
                    -NAME               => $row->{'ID_DEFAULT'},
                    -SOURCE             => 'Glovar',
            );
            $self->get_DBLinks($var);
            $varfeat->variation($var);
            
            $cons{$key} = $cons_rank;
            $varfeats{$key} = $varfeat; 
        }
    }

    #&eprof_end('clone_sql');
    #&eprof_dump(\*STDERR);
    
    return [values %varfeats];
}                                       

=head2 fetch_SNP_by_id

  Arg[1]      : String - Variation ID
  Example     : my $variation = $glovar_adaptor->fetch_SNP_by_id($id);
  Description : retrieve variations from Glovar by ID
  Return type : Listref of Bio::EnsEMBL::Variation::VariationFeature objects.
  Exceptions  : none
  Caller      : $self

=cut

sub fetch_SNP_by_id  {
    my ($self, $id) = @_;
    #&eprof_start('fetch_snp_by_id');
    
    my $dnadb = Bio::EnsEMBL::Registry->get_DNAAdaptor($ENV{'ENSEMBL_SPECIES'}, 'glovar');
    unless ($dnadb) {
        warn "ERROR: No dnadb attached to Glovar.\n";
        return;
    }
    
    ## SNP query
    my $q1 = qq(
        SELECT
                distinct(ss.id_snp)         as internal_id,
                ss.default_name             as id_default,
                ms.position                 as snp_start,
                ms.end_position             as snp_end,
                ms.is_revcomp               as snp_strand,
                scd.description             as validated,
                ss.alleles                  as alleles,
                svd.description             as snpclass,
                cd.chromosome               as chr_name,
                sseq.id_sequence            as nt_id,
                sseq.database_seqnname      as seq_name,
                sseq.database_source        as database_source
        FROM    
                snp_sequence sseq,
                mapped_snp ms,
                snp,
                snpvartypedict svd,
                snp_confirmation_dict scd,
                snp_summary ss,
                chromosomedict cd
        WHERE   ss.default_name = ?
        AND     sseq.id_sequence = ms.id_sequence
        AND     ms.id_snp = ss.id_snp
        AND     ss.id_snp = snp.id_snp
        AND     snp.var_type = svd.id_dict
        AND     ss.confirmation_status = scd.id_dict
        AND     sseq.chromosome = cd.id_dict
        AND     sseq.is_current = 1
    );

    my @snps = ();
    my $sth1;

    eval {
        $sth1 = $self->prepare($q1);
        $sth1->execute($id);
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return([]);
    }

    # loop over all SNP mappings found and pick one; mappings to clones
    # take preference over mappings to NT_contigs
    my (@seq_nt, @seq_clone);
    while (my $r = $sth1->fetchrow_hashref()) {
        return([]) unless keys %{$r};
        if ($r->{'SEQ_NAME'} =~ /^NT/) {
            push @seq_nt, $r;
        } else {
            push @seq_clone, $r;
        }
    }
    # if more than one NT or clone mapping has been returned, something is
    # wrong with snp_sequence.is_current, so print a warning
    if (@seq_nt > 1 or @seq_clone > 1) {
        warning(
            "More than one mapping of SNP to NT_contig ("
            . join(", ", map { $_->{'SEQ_NAME'} } @seq_nt)
            . ") or clone (" 
            . join(", ", map { $_->{'SEQ_NAME'} } @seq_clone)
            . ")."
        );
    }

    # loop over all mappings returned; try clones first; you're done once
    # you've managed to transform to chromosomal coords successfully
    my $varfeat;
    SEQ:
    foreach my $row (@seq_clone, @seq_nt) {
        $row->{'SNP_END'} ||= $row->{'SNP_START'};
        my $snp_start = $row->{'SNP_START'};
        my $id_seq = $row->{'NT_ID'};

        # get clone the SNP is on
        my $q2 = qq(
            SELECT
                    cs.database_seqname     as embl_acc,
                    csm.start_coordinate    as clone_start,
                    csm.end_coordinate      as clone_end,
                    csm.contig_orientation  as clone_strand
            FROM    clone_seq cs,
                    clone_seq_map csm
            WHERE   csm.id_sequence = '$id_seq'
            AND     cs.id_cloneseq = csm.id_cloneseq
            AND     (csm.start_coordinate < $snp_start)
            AND     (csm.end_coordinate > $snp_start)
        );
        my $sth2;
        eval {
            $sth2 = $self->prepare($q2);
            $sth2->execute();
        }; 
        if ($@){
            warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
            return([]);
        }
        my $j;
        CLONE:
        while (my ($embl_acc, $clone_start, $clone_end, $clone_strand) = $sth2->fetchrow_array()) {
            $j++;
            ## map to chromosome
            # you might get more than one clone back from Glovar, since it
            # contains the whole clones, not only the golden parts; if you
            # managed to transform to chromosome, you already had the right
            # one, so skip
            next CLONE if ($varfeat);
            
            # get clone from core db
            # if no clone was found, you've picked the wrong snp_sequence
            # try the next one
            my $clone = $dnadb->get_SliceAdaptor->fetch_by_region('clone', $embl_acc);
            next CLONE unless ($clone);
            
            # calculate clone coordinates for SNP
            my ($start, $end);
            if ($clone_strand == 1) {
                $start = $row->{'SNP_START'} - $clone_start + 1;
                $end = $row->{'SNP_END'} - $clone_start + 1;
            } else {
                $start = $clone_end - $row->{'SNP_END'} + 1;
                $end = $clone_end - $row->{'SNP_START'} + 1;
            }
            next CLONE if ($start < 0);

            $varfeat = Bio::EnsEMBL::Variation::VariationFeature->new(-dbID => $row->{'INTERNAL_ID'});
            $varfeat->slice($clone);
            $varfeat->start($start);
            $varfeat->end($end);
            $varfeat->strand($row->{'SNP_STRAND'}*$clone_strand);
            $varfeat = $varfeat->transform('chromosome');
        }
        warn "WARNING: Multiple clones ($j) returned" if ($j > 1);
        
        # try next snp_sequence if you couldn't transform this one
        next SEQ unless $varfeat;
        
        my $var = Bio::EnsEMBL::Variation::Variation->new(-dbID => $row->{'INTERNAL_ID'});
        $varfeat->variation_name($id);
        $var->name($id);
        $varfeat->seq_region_name($row->{'CHR_NAME'});
        $varfeat->source('Glovar');
        $var->source('Glovar');
        $var->adaptor($self);
        
        # alleles
        $varfeat->allele_string($row->{'ALLELES'});
        # temporary hack; change sql query to get data from snp_variation,
        # allele_frequency, population
        foreach my $al (split(/\|/, $row->{'ALLELES'})) {
            my $allele = Bio::EnsEMBL::Variation::Allele->new(-allele => $al);
            $var->add_Allele($allele);
        }

        # get flanking sequence from core
        my $slice = $dnadb->get_SliceAdaptor->fetch_by_region(
            'chromosome',
            $row->{'CHR_NAME'},
            $varfeat->start - 25,
            $varfeat->end + 25,
        );
        $slice = $slice->invert if ($row->{'SNP_STRAND'} == -1);
        my $seq = $slice->seq;

        # determine end of upstream sequence depending on range type (in-dels
        # of type "between", i.e. start !== end, are actually inserts)
        my $up_end = 25;
        $up_end++ if (($row->{'SNPCLASS'} eq "SNP - indel") && ($varfeat->start ne $varfeat->end));
        $var->five_prime_flanking_seq(substr($seq, 0, $up_end));
        $var->three_prime_flanking_seq(substr($seq, 26));
        # consequences and  DBLinks
        $self->get_consequences($varfeat);
        $self->get_DBLinks($var);

        # validation state
        $varfeat->add_validation_state($VSTATE_MAP{$row->{'VALIDATED'}});
        $var->add_validation_state($VSTATE_MAP{$row->{'VALIDATED'}});

        # population genotypes
        # $self->get_population_genotypes($var);

        # add variation to variationFeature
        $varfeat->variation($var);
    }

    #&eprof_end('fetch_snp_by_id');
    #&eprof_dump(\*STDERR);

    $varfeat ? (return [$varfeat]) : (return([]));
}

=head2 get_DBLinks

  Arg[1]      : Bio::EnsEMBL::SNP object
  Example     : $glovar_adaptor->get_DBLinks($snp, '104567');
  Description : adds external database links to snp object
  Return type : none
  Exceptions  : none
  Caller      : $self

=cut

sub get_DBLinks {
    my ($self, $var) = @_;
    my $q = qq(
        SELECT
                snp_name.SNP_NAME               as NAME,
                snpnametypedict.DESCRIPTION     as TYPE
        FROM    
                snp_name,
                snpnametypedict
        WHERE   snp_name.ID_SNP = ?
        AND     snp_name.SNP_NAME_TYPE = snpnametypedict.ID_DICT
    );
    my $sth;
    eval {
        $sth = $self->prepare($q);
        $sth->execute($var->dbID);
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return;
    }

    while (my $xref = $sth->fetchrow_hashref()) {
        $var->add_synonym($xref->{'TYPE'}, $xref->{'NAME'});
    }
}

=head2 get_consequences

  Arg[1]      : Bio::EnsEMBL::Variation::Variation object
  Example     : $glovar_adaptor->get_consequences($var);
  Description : Adds a TranscriptVariation object to the variation
  Return type : none
  Exceptions  : none
  Caller      : $self

=cut

sub get_consequences {
    my ($self, $varfeat) = @_;
    my $q = qq(
        SELECT
                ptd.description         as pos_type,
                sgc_dict.description    as consequence,
                cs.name                 as transcript_stable_id,
                sgc.transcript_position as cdna_start
        FROM    
                coding_sequence cs,
                snp_gene_consequence sgc
        LEFT JOIN
                position_type_dict ptd on sgc.position_description = ptd.id_dict
        LEFT JOIN
                sgc_dict on sgc.consequence = sgc_dict.id_dict
        WHERE   sgc.id_snp = ?
        AND     sgc.id_codingseq = cs.id_codingseq
        AND     cs.design_entry = ?
    );
    my $sth;
    eval {
        $sth = $self->prepare($q);
        $sth->execute($varfeat->{'dbID'}, $self->consequence_exp);
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return;
    }

    while (my $row = $sth->fetchrow_hashref) {
        # add consequence
        my $consequence_type = $CONSEQUENCE_TYPE_MAP{$row->{'POS_TYPE'}." ".$row->{'CONSEQUENCE'}};

        my $key = join(":", $row->{'TRANSCRIPT_STABLE_ID'}, $row->{'CDNA_START'}, $consequence_type);

        # only add consequence once (workaround for duplicates in db)
        my $found_tvar;
        foreach my $oldtvar (@{ $varfeat->get_all_TranscriptVariations || [] }) {
            if (join(":",   $oldtvar->transcript->stable_id,
                            $oldtvar->cdna_start,
                            $oldtvar->consequence_type
                    ) eq $key) {
                $found_tvar = 1;
            }
        }
        
        unless ($found_tvar) {
            $varfeat->add_consequence_type( [$consequence_type] );

            # add TranscriptVariation object
            my $trans = Bio::EnsEMBL::Transcript->new(
                -STABLE_ID => $row->{'TRANSCRIPT_STABLE_ID'},
            );
            my $tvar = Bio::EnsEMBL::Variation::TranscriptVariation->new_fast({
                transcript          => $trans,
                cdna_start          => $row->{'CDNA_START'},
                cdna_end            => $row->{'CDNA_START'},
                consequence_type    => [ $consequence_type ],
            });
            $varfeat->add_TranscriptVariation($tvar);
        }
    }
}

=head2 get_population_genotypes

  Arg[1]      : Bio::EnsEMBL::Variation::Variation object
  Example     : $self->get_population_genotypes($var);
  Description : Adds PopulationGenotype objects to a variation by fetching
                population genotype info from the db
  Return type : none
  Exceptions  : thrown if no Bio::EnsEMBL::Variation::Variation is supplied
  Caller      : internal

=cut

sub get_population_genotypes {
    my ($self, $var) = @_;
    unless ($var->isa('Bio::EnsEMBL::Variation::Variation')) {
        throw("You must provide a Bio::EnsEMBL::Variation::Variation object.");
    }
    my $q = qq(
        SELECT
                sv.var_string       as allele,
                af.frequency        as frequency,
                p.description       as pop_name,
                ao.sample_size      as sample_size
        FROM
                snp_variation sv,
                allele_frequency af,
                assay_outcome ao,
                population p
        WHERE   sv.id_snp = ?
        AND     sv.id_var = af.id_var
        AND     af.id_outcome = ao.id_outcome
        AND     ao.id_pop = p.id_pop
    );
    my $sth;
    eval {
        $sth = $self->prepare($q);
        $sth->execute($var->dbID);
    }; 
    if ($@){
        warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
        return;
    }

    my $pop;
    while (my $row = $sth->fetchrow_hashref) {
        # collect genotypes by population
        $pop->{$row->{'POP_NAME'}}->{'sample_size'} = $row->{'SAMPLE_SIZE'};
        push @{ $pop->{$row->{'POP_NAME'}}->{'frequency'} }, $row->{'FREQUENCY'};
        push @{ $pop->{$row->{'POP_NAME'}}->{'alleles'} }, $row->{'ALLELE'};
    }

    foreach my $p (keys %$pop) {
        my $population = Bio::EnsEMBL::Variation::Population->new(
            -dbID       => $p,
            -NAME       => $p,
            -SIZE       => $pop->{$p}->{'size'},
        );

        # add PopulationGenotype for each genotype
        # genotype frequencies are calculated by combinatorics from allele
        # frequencies, which is biologically not correct.
        # ToDo: find the right data in the database
        my ($allele1, $allele2) = @{ $pop->{$p}->{'alleles'} };
        my ($freq1, $freq2) = @{ $pop->{$p}->{'frequency'} };

        # homozygous genotypes
        my $pop_genotype = Bio::EnsEMBL::Variation::PopulationGenotype->new(
            -dbID       => $p,
            -ALLELE1    => $allele1,
            -ALLELE2    => $allele1,
            -FREQUENCY  => $freq1**2,
        );
        $pop_genotype->population($population);
        $var->add_PopulationGenotype($pop_genotype);
        
        my $pop_genotype = Bio::EnsEMBL::Variation::PopulationGenotype->new(
            -dbID       => $p,
            -ALLELE1    => $allele2,
            -ALLELE2    => $allele2,
            -FREQUENCY  => $freq2**2,
        );
        $pop_genotype->population($population);
        $var->add_PopulationGenotype($pop_genotype);

        # heterozygous genotype
        my $pop_genotype = Bio::EnsEMBL::Variation::PopulationGenotype->new(
            -dbID       => $p,
            -ALLELE1    => $allele1,
            -ALLELE2    => $allele2,
            -FREQUENCY  => $freq1*$freq2*2,
        );
        $pop_genotype->population($population);
        $var->add_PopulationGenotype($pop_genotype);
    }
}

=head2 consequence_exp

  Arg[1]      : (optional) consequence experiment id
  Example     : $glovar_adaptor->consequence_ext(2046);
  Description : getter/setter for the consequence experiment
                (coding_sequence.design_entry in the glovar db)
  Return type : String - consequence experiment id
  Exceptions  : none
  Caller      : general

=cut

sub consequence_exp {
    my ($self, $exp) = @_;
    if ($exp) {
        $self->{'consequence_exp'} = $exp;
    }
    return $self->{'consequence_exp'};
}

=head2 get_source_version

  Example     : my $version = $glovar_adaptor->get_source_version;
  Description : This method is just for compatibility with
                Bio::EnsEMBL::Variation API.
  Return type : undef
  Exceptions  : none
  Caller      : general

=cut

sub get_source_version {
    return undef;
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
  Example     : my $track_name = $snp_adaptor->track_name;
  Description : returns the track name
  Return type : String - track name
  Exceptions  : none
  Caller      : Bio::EnsEMBL::Slice,
                Bio::EnsEMBL::ExternalData::ExternalFeatureAdaptor

=cut

sub track_name {
    return("GlovarSNP");
}

1;

