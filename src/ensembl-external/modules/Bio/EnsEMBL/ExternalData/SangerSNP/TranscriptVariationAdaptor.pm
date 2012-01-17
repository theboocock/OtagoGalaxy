# EnsEMBL Sanger SNP adaptor 
#
# Copyright EnsEMBL
#
# Author: Steve Searle
# 

=head1 NAME

Bio::EnsEMBL::ExternalData::SangerSNP::TranscriptVariationAdaptor

=head1 SYNOPSIS

A SNP adaptor which sits over the Sanger SNP database.  Provides a means of 
getting SNPs out of the Sanger SNP database as 
Bio::EnsEMBL::Variation::VariationFeature objects. 

=head1 CONTACT

Post questions to the EnsEMBL developer list: <ensembl-dev@ebi.ac.uk> 

=head1 APPENDIX

=cut

use strict;

package Bio::EnsEMBL::ExternalData::SangerSNP::TranscriptVariationAdaptor;

use Bio::EnsEMBL::ExternalData::Variation;
use Bio::EnsEMBL::Variation::TranscriptVariation;
use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::External::ExternalFeatureAdaptor;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;

use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor Bio::EnsEMBL::External::ExternalFeatureAdaptor );

our %CONSEQUENCE_TYPE_MAP = (
        'Coding Synonymous'             => 'SYNONYMOUS_CODING',
        'Coding Non-synonymous'         => 'NON_SYNONYMOUS_CODING',
        'Coding Stop gained'            => 'STOP_GAINED',
        'Coding Stop lost'              => 'STOP_LOST',
# Coding Indel might NOT be frameshift
        'Coding Indel'                  => 'FRAMESHIFT_CODING',
        'Non-coding exonic Non-coding'  => 'UTR',
        'Intronic Non-coding'           => 'INTRONIC',
        'Upstream Non-coding'           => 'UPSTREAM',
);


sub coordinate_systems {
  return ("ASSEMBLY");
}

  
sub fetch_all_by_VariationFeatures {
  my ($self, $vf_ref) = @_;

  if(ref($vf_ref) ne 'ARRAY') {
    throw('ArrayRef of Bio::EnsEMBL::Variation::VariationFeature expected');
  }

  my %vf_by_id;
  my %v_by_id;

  %vf_by_id = map {$_->dbID() . ":" . ($_->start + $_->slice->start - 1), $_ } @$vf_ref;
  %v_by_id = map {$_->dbID(), $_ } @$vf_ref;
  my $instr = join (",",keys( %v_by_id));
  my $q = qq(
      SELECT
              sgc.id_snp              as idsnp,
              ptd.description         as pos_type,
              sgc_dict.description    as consequence,
              cs.name                 as transcript_stable_id,
              sgc.transcript_position as cdna_start,
              sgc.genomic_position    as gen_pos
      FROM    
              coding_sequence cs,
              snp_gene_consequence sgc,
              position_type_dict ptd,
              sgc_dict
      WHERE   sgc.id_snp in ($instr)
      AND     sgc.consequence = sgc_dict.id_dict
      AND     sgc.position_description = ptd.id_dict
      AND     sgc.id_codingseq = cs.id_codingseq
      AND     cs.design_entry = ?
  );
  my $sth;
  eval {
      #print $q . "\n";
      $sth = $self->prepare($q);
      $sth->execute($self->consequence_exp);
  }; 
  if ($@){
      warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
      return;
  }

  #print "Finished query - now making features\n";
  my %trans_hash;

  # Mark all variation features as having had tvs added
  foreach my $vf (@$vf_ref) {
    $vf->{transcriptVariations} = [];
  }

  my @tvs;
  while (my $row = $sth->fetchrow_hashref) {
    #add to the variation feature object all the transcript variations
    my $conskey = $row->{'POS_TYPE'}." ".$row->{'CONSEQUENCE'};
    #print "conskey = $conskey\n";
    my $consequence_type = $CONSEQUENCE_TYPE_MAP{$conskey};
    #print " idsnp = " . $row->{IDSNP} . "\n";

    my $vfkey = $row->{IDSNP} . ":" . $row->{GEN_POS};

    if (exists($vf_by_id{$vfkey})) {
      $vf_by_id{$vfkey}->add_consequence_type($consequence_type);
  
      # add TranscriptVariation object
      my $tsid = $row->{'TRANSCRIPT_STABLE_ID'};
      if (!exists($trans_hash{$tsid})) {
        #print "fetching transcript $tsid\n";
        $trans_hash{$tsid} = $self->ensembl_db->get_TranscriptAdaptor->fetch_by_stable_id($tsid);
      }
  
      my $tvar = Bio::EnsEMBL::Variation::TranscriptVariation->new_fast({
             transcript          => $trans_hash{$tsid},
             cdna_start          => $row->{'CDNA_START'},
             cdna_end            => $row->{'CDNA_START'},
             consequence_type    => $consequence_type,
         });
  
  
      $vf_by_id{$vfkey}->add_TranscriptVariation( $tvar );
      push @tvs,$tvar;
    }
  }
  #print "Finished making features\n";
  return \@tvs;
}

sub fetch_all_by_postype_consequence {
  my ($self, $postype, $consequence) = @_;

  my $q = qq(
      SELECT
              sgc.id_snp              as idsnp,
              ptd.description         as pos_type,
              sgc_dict.description    as consequence,
              cs.name                 as transcript_stable_id,
              sgc.transcript_position as cdna_start,
              sgc.genomic_position    as gen_pos
      FROM    
              coding_sequence cs,
              snp_gene_consequence sgc,
              position_type_dict ptd,
              sgc_dict
      WHERE   sgc_dict.description = ?
      AND     ptd.description = ?
      AND     sgc.consequence = sgc_dict.id_dict
      AND     sgc.position_description = ptd.id_dict
      AND     sgc.id_codingseq = cs.id_codingseq
      AND     cs.design_entry = ?
  );
  my $sth;
  eval {
      # print $q . "\n";
      $sth = $self->prepare($q);
      $sth->execute($consequence,$postype,$self->consequence_exp);
  }; 
  if ($@){
      warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
      return;
  }

  #print "Finished query - now making features\n";
  my %trans_hash;
  my %vf_hash;

  my @tvs;
  while (my $row = $sth->fetchrow_hashref) {
    #add to the variation feature object all the transcript variations
    my $conskey = $row->{'POS_TYPE'}." ".$row->{'CONSEQUENCE'};
    my $consequence_type = $CONSEQUENCE_TYPE_MAP{$conskey};

    # add TranscriptVariation object
    my $tsid = $row->{TRANSCRIPT_STABLE_ID};
    if (!exists($trans_hash{$tsid})) {
      #print "fetching transcript $tsid\n";
      $trans_hash{$tsid} = $self->ensembl_db->get_TranscriptAdaptor->fetch_by_stable_id($tsid);
    }

    my $vfid = $row->{IDSNP};
    my $vfkey = $row->{IDSNP} . ":" . $row->{GEN_POS};

    if (!exists($vf_hash{$vfkey})) {
      #print "fetching variation $vfid at " . $row->{GEN_POS} . "\n";
      $vf_hash{$vfkey} = $self->db->get_VariationAdaptor->fetch_by_dbID_position_range($vfid,$trans_hash{$tsid}->seq_region_name, 
                                                                                      $row->{GEN_POS}, $row->{GEN_POS});
    }

    if (defined($vf_hash{$vfkey})) {
      my $tvar = Bio::EnsEMBL::Variation::TranscriptVariation->new_fast({
             transcript          => $trans_hash{$tsid},
             cdna_start          => $row->{CDNA_START},
             cdna_end            => $row->{CDNA_START},
             consequence_type    => $consequence_type,
             variation_feature   => $vf_hash{$vfkey},
         });
  
  
      $vf_hash{$vfkey}->add_TranscriptVariation( $tvar );
      $vf_hash{$vfkey}->add_consequence_type($consequence_type);
  
      push @tvs,$tvar;
    } else {
      print "Missing variation feature " . $row->{IDSNP} . " for transcript " . $tsid . 
            " " . $trans_hash{$tsid}->seq_region_name . " " . $trans_hash{$tsid}->start . " " . 
            $trans_hash{$tsid}->end . " at " . $row->{GEN_POS} . "\n";
    }
  }
  #print "Finished making features\n";
  return \@tvs;
}

sub fetch_all_by_transcript_stable_id {
  my ($self, $trans_stable_id) = @_;

  my $q = qq(
      SELECT
              sgc.id_snp              as idsnp,
              ptd.description         as pos_type,
              sgc_dict.description    as consequence,
              cs.name                 as transcript_stable_id,
              sgc.transcript_position as cdna_start,
              sgc.genomic_position    as gen_pos
      FROM    
              coding_sequence cs,
              snp_gene_consequence sgc,
              position_type_dict ptd,
              sgc_dict
      WHERE   cs.name = ?
      AND     sgc.consequence = sgc_dict.id_dict
      AND     sgc.position_description = ptd.id_dict
      AND     sgc.id_codingseq = cs.id_codingseq
      AND     cs.design_entry = ?
  );
  my $sth;
  eval {
      # print $q . "\n";
      $sth = $self->prepare($q);
      $sth->execute($trans_stable_id,$self->consequence_exp);
  }; 
  if ($@){
      warn("ERROR: SQL failed in " . (caller(0))[3] . "\n$@");
      return;
  }

  #print "Finished query - now making features\n";
  my %trans_hash;
  my %vf_hash;

  my @tvs;
  while (my $row = $sth->fetchrow_hashref) {
    #add to the variation feature object all the transcript variations
    my $conskey = $row->{'POS_TYPE'}." ".$row->{'CONSEQUENCE'};
    my $consequence_type = $CONSEQUENCE_TYPE_MAP{$conskey};

    # add TranscriptVariation object
    my $tsid = $row->{TRANSCRIPT_STABLE_ID};
    if (!exists($trans_hash{$tsid})) {
      #print "fetching transcript $tsid\n";
      $trans_hash{$tsid} = $self->ensembl_db->get_TranscriptAdaptor->fetch_by_stable_id($tsid);
    }

    my $vfid = $row->{IDSNP};
    my $vfkey = $row->{IDSNP} . ":" . $row->{GEN_POS};

    if (!exists($vf_hash{$vfid})) {
      #print "fetching variation $vfid\n";
      $vf_hash{$vfkey} = $self->db->get_VariationAdaptor->fetch_by_dbID_position_range($vfid,$trans_hash{$tsid}->seq_region_name, 
                                                                                       $row->{GEN_POS},$row->{GEN_POS});
    }

    if (defined($vf_hash{$vfid})) {
      my $tvar = Bio::EnsEMBL::Variation::TranscriptVariation->new_fast({
             transcript          => $trans_hash{$tsid},
             cdna_start          => $row->{CDNA_START},
             cdna_end            => $row->{CDNA_START},
             consequence_type    => $consequence_type,
             variation_feature   => $vf_hash{$vfkey},
         });
  
  
      $vf_hash{$vfkey}->add_TranscriptVariation( $tvar );
      $vf_hash{$vfkey}->add_consequence_type($consequence_type);
  
      push @tvs,$tvar;
    } else {
      print "Missing variation feature " . $row->{IDSNP} . " for transcript " . $tsid . 
            " " . $trans_hash{$tsid}->seq_region_name . " " . $trans_hash{$tsid}->start . " " . 
            $trans_hash{$tsid}->end . " at " . $row->{GEN_POS} . "\n";
    }
  }
  #print "Finished making features\n";
  return \@tvs;
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


1;
