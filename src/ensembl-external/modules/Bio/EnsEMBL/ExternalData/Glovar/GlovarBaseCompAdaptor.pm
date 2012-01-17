=head1 NAME

Bio::EnsEMBL::ExternalData::Glovar::GlovarBaseCompAdaptor -
Object adaptor for Glovar base composition

=head1 SYNOPSIS

$db_adaptor = Bio::EnsEMBL::ExternalData::Glovar::DBAdaptor->new(
                                         -user   => 'ensro',
                                         -pass   => 'secret',
                                         -dbname => 'snp',
                                         -host   => 'go_host',
                                         -driver => 'Oracle'
);
my $basecomp_adaptor = $db_adaptor->get_GlovarBaseCompAdaptor;
my $listref  = $basecomp_adaptor->fetch_all_by_Slice($slice);

=head1 DESCRIPTION

This module is an entry point into a Glovar database. It allows you to retrieve
base composition data from the database.

=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 AUTHOR

Jody Clements <jc3@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

package Bio::EnsEMBL::ExternalData::Glovar::GlovarBaseCompAdaptor;

use strict;
use vars qw(@ISA);

use Bio::EnsEMBL::ExternalData::Glovar::BaseComposition;
use Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end eprof_dump);

@ISA = qw(Bio::EnsEMBL::ExternalData::Glovar::GlovarAdaptor);

=head2 fetch_all_by_Slice

  Arg [1]    : Bio::EnsEMBL::Slice
  Arg [2]    : (optional) boolean $is_lite
               Flag indicating if 'light weight' objects should be obtained
  Example    : @list = @{$basecomp_adaptor->fetch_all_by_Slice($slice)};
  Description: Retrieves a list of base composition objects on a slice in
               slice coordinates 
  Returntype : Listref of Bio::EnsEMBL::External::Glovar::BaseComposition
               objects
  Exceptions : none
  Caller     : Bio::EnsEMBL::Slice::get_all_ExternalFeatures

=cut

sub fetch_all_by_Slice {
  my ($self, $slice, $is_light) = @_;

  unless($slice->assembly_name() && $slice->assembly_version()){
      warn("Cannot determine assembly name and version from Slice in GlovarAdaptor!\n");
      return([]);
  }

  my @f = ();
  if($is_light){
    push @f, @{$self->fetch_Light_Base_Comp_by_chr_start_end($slice)};
  } else {
    push @f, @{$self->fetch_Base_Comp_by_chr_start_end($slice)};
  }
  return(\@f);
}

=head2 fetch_Light_Base_Comp_by_chr_start_end

  Arg [1]    : Bio::EnsEMBL::Slice
  Example    : @list = @{$basecomp_adaptor->fetch_Light_Base_Comp_by_chr_start_end($slice)};
  Description: Retrieves a list of base composition objects on a slice in
               slice coordinates 
  Returntype : Listref of Bio::EnsEMBL::External::Glovar::BaseComposition
               objects. Returns lightweight objects for drawing purposes
  Exceptions : none
  Caller     : $self->fetch_all_by_Slice

=cut

sub fetch_Light_Base_Comp_by_chr_start_end {
    my ($self, $slice) = @_;
    my $slice_chr    = $slice->chr_name();
    my $slice_start  = $slice->chr_start();
    my $slice_end    = $slice->chr_end();
    my $slice_strand = $slice->strand();
    my $ass_name     = $slice->assembly_name();
    my $ass_version  = $slice->assembly_version();

    &eprof_start('glovar_basecomp');

    ## NOTE:
    ## all code here assumes that ssm.contig_orientation is always 1!

    my $q = qq(
        SELECT     
                (rp.position + ssm.start_coordinate -1) as position,
                rp.genomic_base as genomic_base,
                COUNT(decode (sp.base,'A',1
                        ,'G',NULL
                        ,'T',NULL
                        ,'C',NULL)) as A,
                COUNT(decode (sp.base,'A',NULL
                        ,'G',1
                        ,'T',NULL
                        ,'C',NULL)) as G,
                COUNT(decode (sp.base,'A',NULL
                        ,'G',NULL
                        ,'T',NULL
                        ,'C',1)) as C,
                COUNT(decode (sp.base,'A',NULL
                        ,'G',NULL
                        ,'T',1
                        ,'C',NULL)) as T,
                COUNT(decode (ed.id_dict,0,1
                        ,1,NULL
                        ,2,NULL
                        ,3,NULL)) as E0,
                COUNT(decode (ed.id_dict,0,NULL
                        ,1,1
                        ,2,NULL
                        ,3,NULL)) as E1,
                COUNT(decode (ed.id_dict,0,NULL
                        ,1,NULL
                        ,2,1
                        ,3,NULL)) as E2,
                COUNT(decode (ed.id_dict,0,NULL
                        ,1,NULL
                        ,2,NULL
                        ,3,1)) as E3
        FROM    chrom_seq cs,
                seq_seq_map ssm,
                snp_sequence ss,
                reference_position rp,
                sequence_position sp,
                snp_read sr,
                individual i,
                ethnicitydict ed
        WHERE   cs.database_seqname = '$slice_chr'
        AND     cs.is_current = 1
        AND     cs.id_chromseq = ssm.id_chromseq
        AND     ssm.sub_sequence = ss.id_sequence
        AND     ss.id_sequence = rp.id_sequence
        AND     rp.id_sequence = sp.repo_id_sequence
        AND     sp.repo_position = rp.position
        AND     sp.is_nqs = 1
        AND     sp.seq_content = sr.id_read
        AND     sr.dna_content = i.id_ind
        AND     i.ethnicity = ed.id_dict
        AND     rp.position
                BETWEEN
                ($slice_start - ssm.start_coordinate + 1)
                AND
                ($slice_end - ssm.start_coordinate + 1)
        GROUP BY
                (rp.position + ssm.start_coordinate),
                rp.genomic_base
        ORDER by position
    );

    my $sth;
    eval {
        $sth = $self->prepare($q);
        $sth->execute();
    };
    if ($@){
        warn("ERROR: SQL failed in GlovarAdaptor->fetch_Light_Base_Comp_by_chr_start_end()!\n$@");
        return([]);
    }

    my @bases = ();

    my $refs = $sth->fetchall_arrayref();

    for my $ref(@$refs){
        my($position,$genomic_base,$A_count,$G_count,$C_count,$T_count,$e0,$e1,$e2,$e3) = @$ref;

        my $basecomp = Bio::EnsEMBL::ExternalData::Glovar::BaseComposition->new_fast({
                'position'     => $position - $slice_start + 1,
                'genomic_base' => $genomic_base,
                'alleles'      => {
                    'T' => $T_count,
                    'G' => $G_count,
                    'A' => $A_count,
                    'C' => $C_count,
                },
                'ethnicity'    => {
                    'unknown' => $e0,
                    'Caucasian' => $e1,
                    'Asian' => $e2,
                    'African-American' => $e3,
                },
                '_gsf_strand'  => 1,
                });
        push (@bases, $basecomp);

    }
    &eprof_end('glovar_basecomp');
    return (\@bases);
}

=head2 fetch_Base_Comp_by_chr_start_end

  Arg [1]    : Bio::EnsEMBL::Slice
  Example    : @list = @{$basecomp_adaptor->fetch_Base_Comp_by_chr_start_end($slice)};
  Description: Retrieves a list of base composition objects on a slice in
               slice coordinates 
  Returntype : Listref of Bio::EnsEMBL::External::Glovar::BaseComposition
               objects
  Exceptions : none
  Caller     : $self->fetch_all_by_Slice

=cut

sub fetch_Base_Comp_by_chr_start_end  {
    my ($self,$slice) = @_;
    my @vars = ();

    ## to be implemented
    
    return(\@vars);
}

=head2 track_name

  Arg[1]      : none
  Example     : my $track_name = $basecomp_adaptor->track_name;
  Description : returns the track name
  Return type : String - track name
  Exceptions  : none
  Caller      : Bio::EnsEMBL::Slice,
                Bio::EnsEMBL::ExternalData::ExternalFeatureAdaptor

=cut

sub track_name {
    my ($self) = @_;
    return("GlovarBaseComp");
}

1;
