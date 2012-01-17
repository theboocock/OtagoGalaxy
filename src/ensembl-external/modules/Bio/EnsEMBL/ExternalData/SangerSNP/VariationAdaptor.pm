# EnsEMBL Sanger SNP adaptor 
#
# Copyright EnsEMBL
#
# Author: Steve Searle
# 

=head1 NAME

Bio::EnsEMBL::ExternalData::SangerSNP::VariationAdaptor

=head1 SYNOPSIS

A SNP adaptor which sits over the Sanger SNP database.  Provides a means of 
getting SNPs out of the Sanger SNP database as 
Bio::EnsEMBL::Variation::VariationFeature objects. 

=head1 CONTACT

Post questions to the EnsEMBL developer list: <ensembl-dev@ebi.ac.uk> 

=head1 APPENDIX

=cut

use strict;

package Bio::EnsEMBL::ExternalData::SangerSNP::VariationAdaptor;

use Bio::EnsEMBL::ExternalData::Variation;
use Bio::EnsEMBL::SNP;
use Bio::EnsEMBL::Variation::VariationFeature;
use Bio::EnsEMBL::Variation::Variation;
use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::External::ExternalFeatureAdaptor;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;

use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor Bio::EnsEMBL::External::ExternalFeatureAdaptor );


sub fetch_all_by_chr_start_end {
  my ($self,$chr,$start,$end) = @_;

  my $assembly = $self->ensembl_db->get_CoordSystemAdaptor->fetch_all->[0]->version();
  
  (my $assembly_name = $assembly) =~ s/[0-9]*$//;
  (my $assembly_version = $assembly) =~ s/[A-Z,a-z]*([0-9]*)$/$1/;

  my $query = qq {
SELECT MAPPED_SNP.ID_SNP,  
          (MAPPED_SNP.POSITION + SEQ_SEQ_MAP.START_COORDINATE -1) AS snppos,
          (MAPPED_SNP.END_POSITION + SEQ_SEQ_MAP.START_COORDINATE -1) AS snpendpos,
          (MAPPED_SNP.IS_REVCOMP * SEQ_SEQ_MAP.CONTIG_ORIENTATION) AS snpstrand,
           CHROM_SEQ.DATABASE_SEQNAME as chrname,
           SNP_SUMMARY.ALLELES,
           SNP_SUMMARY.DEFAULT_NAME
FROM     DATABASE_DICT,
         CHROM_SEQ,
         SEQ_SEQ_MAP,
         MAPPED_SNP,
         SNP_SUMMARY
WHERE     DATABASE_DICT.DATABASE_NAME = '$assembly_name'
    AND   DATABASE_DICT.DATABASE_VERSION = '$assembly_version'
    AND   CHROM_SEQ.DATABASE_SOURCE = DATABASE_DICT.ID_DICT
    AND   CHROM_SEQ.IS_CURRENT = 1
    AND   CHROM_SEQ.DATABASE_SEQNAME='$chr'
    AND   CHROM_SEQ.ID_CHROMSEQ = SEQ_SEQ_MAP.ID_CHROMSEQ
    AND   MAPPED_SNP.ID_SEQUENCE =SEQ_SEQ_MAP.SUB_SEQUENCE
    AND   SNP_SUMMARY.ID_SNP = MAPPED_SNP.ID_SNP
    AND   MAPPED_SNP.IGNORE_REASON IS NULL
    AND   MAPPED_SNP.IS_REVCOMP IS NOT NULL
    AND   (MAPPED_SNP.POSITION + SEQ_SEQ_MAP.START_COORDINATE -1) BETWEEN $start AND $end
ORDER BY MAPPED_SNP.ID_SNP, SNPPOS
  };

  my $sth = $self->prepare($query);

  # print $sth->{Statement} . "\n";

  $sth->execute;
  # print "Query finished\n";

  my @snps;

# Naughty but should speed things up a bit
  my $cur_snp_id = -1;
  my $snp;
  my %ids;
  my $hashref;

  while ($hashref = $sth->fetchrow_hashref) {
    

    if ($hashref->{SNPSTRAND} != 1 && $hashref->{SNPSTRAND} != -1) {
      print STDERR "Got non 1 or -1 strand for " . $hashref->{ID_SNP} . "\n";
    }

    my $start;
    my $end;
    if ($hashref->{SNPPOS} >= $hashref->{SNPENDPOS} ||
       ($hashref->{ALLELES} =~ /-/ && abs($hashref->{SNPPOS}-$hashref->{SNPENDPOS})==1)) {
      $start = $hashref->{SNPENDPOS};
      $end = $hashref->{SNPPOS};
    } else {
      $start = $hashref->{SNPPOS};
      $end = $hashref->{SNPENDPOS};
    }

    if (exists($ids{$hashref->{ID_SNP} . ":" .$start})) {
      print STDERR "Warning: Skipping duplicate for " . $hashref->{ID_SNP} . " at $start\n";
      next;
    }

    my $varfeat = Bio::EnsEMBL::Variation::VariationFeature->new_fast(
      {
        'dbID'              => $hashref->{ID_SNP},
        'adaptor'           => $self,
        'variation_name'    => $hashref->{DEFAULT_NAME},
        'start'             => $start,
        'end'               => $end,
        'strand'            => $hashref->{SNPSTRAND},
        'allele_string'     => $hashref->{ALLELES},
        'source'            => 'SangerSNP',
      });

    $varfeat->slice($self->ensembl_db->get_SliceAdaptor->fetch_by_region('chromosome',
                                                                         $hashref->{CHRNAME}));

    # add minimal Variation object
    my $var = Bio::EnsEMBL::Variation::Variation->new(
        -dbID               => $hashref->{'ID_SNP'},
        -ADAPTOR            => $self,
        -NAME               => $hashref->{'DEFAULT_NAME'},
        -SOURCE             => 'Glovar',
      );

#    my %snp_hash;
#    if ($hashref->{SNPPOS} >= $hashref->{SNPENDPOS} ||
#        ($hashref->{ALLELES} =~ /-/ && abs($hashref->{SNPPOS}-$hashref->{SNPENDPOS})==1)) {
#      $snp_hash{_gsf_start} = $hashref->{SNPENDPOS};
#      $snp_hash{_gsf_end} = $hashref->{SNPPOS};
#    } else {
#      $snp_hash{_gsf_start} = $hashref->{SNPPOS};
#      $snp_hash{_gsf_end} = $hashref->{SNPENDPOS};
#    }
#    if ($hashref->{SNPSTRAND} != 1 && $hashref->{SNPSTRAND} != -1) {
#      print STDERR "Got non 1 or -1 strand\n";
#    }

    push @snps,$varfeat;

    $ids{$hashref->{ID_SNP} . ":" .$start} = 1;
  }

  return \@snps;
}

sub coordinate_systems {
  return ("ASSEMBLY");
}

sub fetch_by_dbID_position_range {
  my ($self,$dbID,$range_chr,$range_start,$range_end) = @_;

  my $assembly = $self->ensembl_db->assembly_type;
  
  (my $assembly_name = $assembly) =~ s/[0-9]*$//;
  (my $assembly_version = $assembly) =~ s/[A-Z,a-z]*([0-9]*)$/$1/;

  my $query = qq {
SELECT DISTINCT MAPPED_SNP.ID_SNP,  
          (MAPPED_SNP.POSITION + SEQ_SEQ_MAP.START_COORDINATE -1) AS snppos,
          (MAPPED_SNP.END_POSITION + SEQ_SEQ_MAP.START_COORDINATE -1) AS snpendpos,
          (MAPPED_SNP.IS_REVCOMP * SEQ_SEQ_MAP.CONTIG_ORIENTATION) AS snpstrand,
           CHROM_SEQ.DATABASE_SEQNAME as chrname,
           SNP_SUMMARY.ALLELES,
           SNP_SUMMARY.DEFAULT_NAME
FROM     DATABASE_DICT,
         CHROM_SEQ,
         SEQ_SEQ_MAP,
         MAPPED_SNP,
         SNP_SUMMARY
WHERE     DATABASE_DICT.DATABASE_NAME = '$assembly_name'
    AND   DATABASE_DICT.DATABASE_VERSION = '$assembly_version'
    AND   CHROM_SEQ.DATABASE_SOURCE = DATABASE_DICT.ID_DICT
    AND   CHROM_SEQ.IS_CURRENT = 1
    AND   CHROM_SEQ.ID_CHROMSEQ = SEQ_SEQ_MAP.ID_CHROMSEQ
    AND   MAPPED_SNP.ID_SEQUENCE =SEQ_SEQ_MAP.SUB_SEQUENCE
    AND   SNP_SUMMARY.ID_SNP = MAPPED_SNP.ID_SNP
    AND   MAPPED_SNP.IS_REVCOMP IS NOT NULL
    AND   SNP_SUMMARY.ID_SNP = $dbID
ORDER BY MAPPED_SNP.ID_SNP, SNPPOS
  };

  my $sth = $self->prepare($query);

  #print $sth->{Statement} . "\n";

  $sth->execute;
  # print "Query finished\n";

  my @snps;

# Naughty but should speed things up a bit
  my $cur_snp_id = -1;
  my $snp;
  my %ids;
  my $hashref;
  while ($hashref = $sth->fetchrow_hashref) {
    
    my $start;
    my $end;
    if ($hashref->{SNPPOS} >= $hashref->{SNPENDPOS} ||
       ($hashref->{ALLELES} =~ /-/ && abs($hashref->{SNPPOS}-$hashref->{SNPENDPOS})==1)) {
      $start = $hashref->{SNPENDPOS};
      $end = $hashref->{SNPPOS};
    } else {
      $start = $hashref->{SNPPOS};
      $end = $hashref->{SNPENDPOS};
    }

    if ($hashref->{CHRNAME} ne $range_chr || $start < $range_start || $start > $range_end) {
      #print "Outside range ($range_chr,$range_start,$range_end) for id $dbID " . $hashref->{CHRNAME} . " $start $end\n"; 
      next;
    }
    #print "In range ($range_chr,$range_start,$range_end) for id $dbID " . $hashref->{CHRNAME} . " $start $end\n"; 
    my $varfeat = Bio::EnsEMBL::Variation::VariationFeature->new_fast(
      {
        'dbID'              => $hashref->{ID_SNP},
        'adaptor'           => $self,
        'variation_name'    => $hashref->{DEFAULT_NAME},
        'start'             => $start,
        'end'               => $end,
        'strand'            => $hashref->{SNPSTRAND},
        'allele_string'     => $hashref->{ALLELES},
        'source'            => 'SangerSNP',
      });

    $varfeat->slice($self->ensembl_db->get_SliceAdaptor->fetch_by_region('chromosome',$hashref->{CHRNAME}));
    # add minimal Variation object
    my $var = Bio::EnsEMBL::Variation::Variation->new(
        -dbID               => $hashref->{'ID_SNP'},
        -ADAPTOR            => $self,
        -NAME               => $hashref->{'DEFAULT_NAME'},
        -SOURCE             => 'Glovar',
      );

    push @snps,$varfeat;
  }

  if (scalar(@snps) > 1) {
    print STDERR "Got multiple vars for $dbID - only returning 1\n";
  }
  return $snps[0];
}

sub fetch_all_by_dbID {
  my ($self,$dbID) = @_;

  my $assembly = $self->ensembl_db->assembly_type;
  
  (my $assembly_name = $assembly) =~ s/[0-9]*$//;
  (my $assembly_version = $assembly) =~ s/[A-Z,a-z]*([0-9]*)$/$1/;

  my $query = qq {
SELECT DISTINCT MAPPED_SNP.ID_SNP,  
          (MAPPED_SNP.POSITION + SEQ_SEQ_MAP.START_COORDINATE -1) AS snppos,
          (MAPPED_SNP.END_POSITION + SEQ_SEQ_MAP.START_COORDINATE -1) AS snpendpos,
          (MAPPED_SNP.IS_REVCOMP * SEQ_SEQ_MAP.CONTIG_ORIENTATION) AS snpstrand,
           CHROM_SEQ.DATABASE_SEQNAME as chrname,
           SNP_SUMMARY.ALLELES,
           SNP_SUMMARY.DEFAULT_NAME
FROM     DATABASE_DICT,
         CHROM_SEQ,
         SEQ_SEQ_MAP,
         MAPPED_SNP,
         SNP_SUMMARY
WHERE     DATABASE_DICT.DATABASE_NAME = '$assembly_name'
    AND   DATABASE_DICT.DATABASE_VERSION = '$assembly_version'
    AND   CHROM_SEQ.DATABASE_SOURCE = DATABASE_DICT.ID_DICT
    AND   CHROM_SEQ.IS_CURRENT = 1
    AND   CHROM_SEQ.ID_CHROMSEQ = SEQ_SEQ_MAP.ID_CHROMSEQ
    AND   MAPPED_SNP.ID_SEQUENCE =SEQ_SEQ_MAP.SUB_SEQUENCE
    AND   SNP_SUMMARY.ID_SNP = MAPPED_SNP.ID_SNP
    AND   MAPPED_SNP.IS_REVCOMP IS NOT NULL
    AND   SNP_SUMMARY.ID_SNP = $dbID
ORDER BY MAPPED_SNP.ID_SNP, SNPPOS
  };

  my $sth = $self->prepare($query);

  #print $sth->{Statement} . "\n";

  $sth->execute;
  # print "Query finished\n";

  my @snps;

# Naughty but should speed things up a bit
  my $cur_snp_id = -1;
  my $snp;
  my %ids;
  my $hashref;
  while ($hashref = $sth->fetchrow_hashref) {
    
    my $start;
    my $end;
    if ($hashref->{SNPPOS} >= $hashref->{SNPENDPOS} ||
       ($hashref->{ALLELES} =~ /-/ && abs($hashref->{SNPPOS}-$hashref->{SNPENDPOS})==1)) {
      $start = $hashref->{SNPENDPOS};
      $end = $hashref->{SNPPOS};
    } else {
      $start = $hashref->{SNPPOS};
      $end = $hashref->{SNPENDPOS};
    }

    my $varfeat = Bio::EnsEMBL::Variation::VariationFeature->new_fast(
      {
        'dbID'              => $hashref->{ID_SNP},
        'adaptor'           => $self,
        'variation_name'    => $hashref->{DEFAULT_NAME},
        'start'             => $start,
        'end'               => $end,
        'strand'            => $hashref->{SNPSTRAND},
        'allele_string'     => $hashref->{ALLELES},
        'source'            => 'SangerSNP',
      });
    $varfeat->slice($self->ensembl_db->get_SliceAdaptor->fetch_by_region('chromosome',$hashref->{CHRNAME}));

    # add minimal Variation object
    my $var = Bio::EnsEMBL::Variation::Variation->new(
        -dbID               => $hashref->{'ID_SNP'},
        -ADAPTOR            => $self,
        -NAME               => $hashref->{'DEFAULT_NAME'},
        -SOURCE             => 'Glovar',
      );

    push @snps,$varfeat;
  }

  return \@snps;
}
1;
