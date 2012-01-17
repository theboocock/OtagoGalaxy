
#
# BioPerl module for Bio::EnsEMBL::ExternalData::GeneSNP
#
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Heikki Lehvaslaiho
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::GeneSNP - class to expand genomic SNP
into full gene variation description 

=head1 SYNOPSIS

    $genesnp = new Bio::EnsEMBL::ExternalData::GeneSNP
                (-gene => $gene,
                 -contig => $contig
		 );
    # $snp is a Bio::EnsEMBL::ExternalData::Variation object
    $var = $genesnp->snp2gene($snp);
    # $var is a Bio::Variation::SeqDiff object
    # or 
    @var = $genesnp->snps2gene(@snps);    


=head1 DESCRIPTION

Bio::EnsEMBL::ExternalData::GeneSNP takes in
L<Bio::EnsEMBL::ExternalData::Variation> objects in genomic (clone,
contig or virtual contig) coordinates and calculates for DNA, RNA and
protein changes in gene coordinates based on information in a
L<Bio::EnsEMBL::Gene> object. The returned object for each SNP
description is L<Bio::Variation::SeqDiff> which links to
L<Bio::Variation::VariantI> compliant objects.

A SNP passed into a GeneSNP object is taken to be a gene SNP (gSNP) if
it is within 5kb of coding region. A RNA and protein level description
objct is created only for coding SNPs (cSNP).

    $is_cSNP = 1 if $var->AAChange;

The IDs are kept as follows:

- All the DBLinks are L<Bio::Annotation::DBLink> objects which are
  passed from Variant into DNAMutation. Primary ID of a SNP is
  $var->DNAMutation->id

- The contig ID is kept in SeqDiff ID : $var->id

- The ID of the transcript ID used to calculate SeqDiff is:
  $var->rna_id

- The ID of the exon where SNP is located is kept in
  DNAMutation->region_value.  The string looks like 'ENSE00000012499
  (1)'. The order number is there to keep track of introns which do
  not have IDs, only an order number. To get exon ID only:
  $var->DNAMutation->region_value =~ /\w+/


=head1 CONTACT

Heikki Lehvaslaiho <heikki@ebi.ac.uk>

Address:

     EMBL Outstation, European Bioinformatics Institute
     Wellcome Trust Genome Campus, Hinxton
     Cambs. CB10 1SD, United Kingdom

=cut

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::ExternalData::GeneSNP;
use vars qw(@ISA );
use strict;
use Bio::EnsEMBL::Root;

# Object preamble - inheritance
@ISA = qw ( Bio::EnsEMBL::Root );

#use Carp;
use Bio::Variation::SeqDiff;
use Bio::Variation::DNAMutation;
use Bio::Variation::RNAChange;
use Bio::Variation::AAChange;
use Bio::Variation::Allele;
use Bio::Tools::CodonTable;
use Bio::EnsEMBL::ExternalData::Variation;
use Bio::Annotation::DBLink;

sub new {
    my($class,@args) = @_;
    my $self;
    $self = {};
    bless $self, $class;

    my ($gene, $contig, $transcript) =
	    $self->_rearrange([qw(GENE
				  CONTIG
				  TRANSCRIPT
				)],@args);
    $gene && $self->gene($gene);
    $contig && $self->contig($contig);
    $transcript && $self->transcript($transcript);
    return $self; # success - we hope!
}

=head2 gene

 Title   : gene
 Usage   : $geneobj = $obj->gene;
 Function: Returns or sets the link-reference to a Gene object.
           If there is no link, it will return undef
 Returns : an obj_ref or undef

=cut


sub gene {
  my ($self,$value) = @_;
  if (defined $value) {
      if( ! $value->isa('Bio::EnsEMBL::Gene') ) {
	  $self->throw("Is not a Bio::EnsEMBL::Gene object but a [$value]");
	  return (undef);
      }
      else {
	  $self->{'gene'} = $value;
      }
  }
  unless (exists $self->{'gene'}) {
      return (undef);
  } else {
      return $self->{'gene'};
  }
}


=head2 transcript

 Title   : transcript
 Usage   : $transcriptobj = $obj->transcript;
 Function: Returns or sets the link-reference to a Transcript object.
           If there is no link, it will return undef
 Returns : an obj_ref or undef

=cut


sub transcript {
  my ($self,$value) = @_;
  if (defined $value) {
      if( ! $value->isa('Bio::EnsEMBL::Transcript') ) {
	  $self->throw("Is not a Bio::EnsEMBL::Transcript object but a [$value]");
	  return (undef);
      }
      else {
	  $self->{'transcript'} = $value;
      }
  }
  unless (exists $self->{'transcript'}) {
      return (undef);
  } else {
      return $self->{'transcript'};
  }
}


=head2 contig

 Title   : contig
 Usage   : $contigobj = $obj->contig;
 Function: Returns or sets the link-reference to a Contig object.
           If there is no link, it will return undef
 Returns : an obj_ref or undef

=cut

sub contig {
  my ($self,$value) = @_;
  if (defined $value) {
    $self->{'contig'} = $value;
  }
  unless (exists $self->{'contig'}) {
      return (undef);
  } else {
      return $self->{'contig'};
  }
}



sub snps2transcript {
  my ($self, @snps) = @_;
  my $seqDiff = undef;

  #sanity checks
  $self->transcript || $self->throw("Set transcript to a Bio::EnsEMBL::Transcript object");
  $self->contig || $self->throw("Set contig to a  Bio::EnsEMBL::RawContig compliant object");

  my @seqDiffs = ();
  my $rna = $self->transcript;
  my $aa = $rna->translation; #Bio::Ensembl::Translation object
  my $aaseq = $rna->translate;
  foreach my $snp (@snps) {
      my $seqDiff = $self->_calculate_gene_coordinates($snp, $rna, $aa, $aaseq);
      $seqDiff && push @seqDiffs, $seqDiff;
  }
  return @seqDiffs;
}

sub snps2gene {
  my ($self, @snps) = @_;
  my $seqDiff = undef;

  #sanity checks
  $self->gene || $self->throw("Set gene to a Bio::EnsEMBL::Gene object");
  $self->contig || $self->throw("Set contig to a  Bio::EnsEMBL::RawContig compliant object");

  my @seqDiffs = ();
  foreach my $rna ($self->gene->each_Transcript) {
      my $aa = $rna->translation; #Bio::Ensembl::Translation object
      my $aaseq = $rna->translate;
      foreach my $snp (@snps) {
	  my $seqDiff = $self->_calculate_gene_coordinates($snp, $rna, $aa, $aaseq);
	  $seqDiff && push @seqDiffs, $seqDiff;
      }
  }
  return @seqDiffs;
}

sub snp2gene {
  my ($self, $snp) = @_;
  my $seqDiff = undef;

  #sanity checks
  #$snp || $self->throw("Give a Bio::EnsEMBL::ExternalData::Variation object as an argument");
  #$snp->isa('Bio::EnsEMBL::ExternalData::Variation') ||
  #    $self->throw("Is not a Bio::EnsEMBL::ExternalData::Variation object but a [$snp]");
  $self->gene || $self->throw("Set gene to a Bio::EnsEMBL::Gene object");
  $self->contig || $self->throw("Set contig to a  Bio::EnsEMBL::RawContig compliant object");

  my @seqDiffs = ();
  foreach my $rna ($self->gene->each_Transcript) {
      #print STDERR $rna->dna_seq->seq, "\n";
      my $aa = $rna->translation; #Bio::Ensembl::Translation object
      #print $aa->id, ", ", $aa->start, ", ", $aa->end, "\n";
      my $aaseq = $rna->translate;
      #print STDERR $aaseq->seq, "\n";

      $seqDiff = $self->_calculate_gene_coordinates($snp, $rna, $aa, $aaseq);
      $seqDiff && push @seqDiffs, $seqDiff;
  }
  return @seqDiffs;
}


sub _calculate_gene_coordinates {
    my ($self, $snp, $rna, $aa, $aaseq) = @_;
    my $seqDiff = undef;
    $snp || $self->throw("Give a Bio::EnsEMBL::ExternalData::Variation object as an argument");
    $snp->isa('Bio::EnsEMBL::ExternalData::Variation') ||
        $self->throw("Is not a Bio::EnsEMBL::ExternalData::Variation object but a [$snp]");

    $rna->isa('Bio::EnsEMBL::Transcript') ||
        $self->throw("Is not a Bio::EnsEMBL::Transcript object but a [$rna]");
    $aa->isa('Bio::EnsEMBL::Translation') ||
        $self->throw("Is not a Bio::EnsEMBL::Translation object but a [$aaseq]");
    $aaseq->isa('Bio::PrimarySeqI') ||
        $self->throw("Is not a Bio::PrimarySeqI object but a [$aaseq]");

    #reject the SNP if it is not withing 5kb of the coding region
    return undef if $snp->start < ($aa->start - 5000);
    return undef if $snp->end > ($aa->end + 5000);
    #only real SNPs taken into account!
    return undef if $snp->start != $snp->start; 

    #
    #first create the container object
    #
    $seqDiff = Bio::Variation::SeqDiff->new();
    $seqDiff->moltype('dna');
    $seqDiff->numbering('entry');
    #$seqDiff->dna_ori(); leave undefined, 
    #we do not want to burden the object with long contig sequnce
    $seqDiff->rna_ori($rna->dna_seq->seq);
    $seqDiff->aa_ori($rna->translate); #slow opeation?
    $seqDiff->id($self->contig->id);
    $seqDiff->rna_id($rna->id);
    $seqDiff->offset($aa->start -1);
    $seqDiff->cds_end($aa->end - $aa->start + 1);
    
    #
    # DNA level
    #
    my $dna_start =  $snp->start - $seqDiff->offset;
    $dna_start < 1 && $dna_start--; # no 0 in the coordinate system!

    my $dnamut = Bio::Variation::DNAMutation->new
	(-start => ($dna_start),
	 -end => ($dna_start),
	 );
    
    $dnamut->mut_number(1);
    $dnamut->proof('experimental'); # given coordianate system
    #$dnamut->isMutation(0);
    
    my (@alleles) = split (/\|/, $snp->alleles); 
    my $dnaA1 = Bio::Variation::Allele->new;
    my $a1 = shift @alleles;
    $dnamut->length(CORE::length $a1);
    $dnaA1->seq($a1);
    $dnamut->allele_ori($dnaA1);
    foreach my $alleleseq (@alleles) {
	my $A2 = Bio::Variation::Allele->new;
	$A2->seq($alleleseq);
	$dnamut->add_Allele($A2);
    }

    $seqDiff->add_Variant($dnamut);
    foreach my $link ($snp->each_DBLink) {
	$dnamut->add_DBLink;
    }
    my $start_pos = $snp->start;
    $dnamut->upStreamSeq
	(lc substr($self->contig->primary_seq->seq, $snp->start -25, 25));
    $dnamut->dnStreamSeq
	(lc substr($self->contig->primary_seq->seq, $snp->start +1, 25));
    my $ref_allele = lc substr($self->contig->primary_seq->seq, $snp->start, 1 );
    $dnaA1->seq ne $ref_allele &&
	$self->warn("Found DNA ref allele: $ref_allele!");

#what if the SNP is closer to either end than 25 nt?

    # where in the gene region the snp is?
    if ($snp->start < $rna->start_exon->start) {
	$dnamut->region('5\'upstream');
    }
    elsif ($snp->start > $rna->end_exon->end) {
	$dnamut->region("3'downstream");
    }
    elsif  ($snp->start < $aa->start) {
	$dnamut->region("5'UTR");
    }
    elsif  ($snp->start > $aa->end) {
	$dnamut->region("3'UTR");
    } else { #coding
	
	my $last_exon_end = 0;
	my $exoncount = 1;
	#my $this_exon;
	my $transcript_loc;
	foreach my $exon ($rna->each_Exon) {
	    if ($snp->start < $exon->start) {
		$dnamut->region('intron');
		$dnamut->region_value($exoncount);
		last;
	    }
	    elsif ($snp->start >= $exon->start and $snp->start <= $exon->end) {
		$dnamut->region('exon');
		$dnamut->region_value($exon->id. " ($exoncount)");
		#$thisexon = $exon->id;
		last;
	    }
	    
	    $exoncount++;
	}   
    }
    #
    # RNA level
    #
    my $rnachange = undef;
    #if ($dnamut->region =~ /UTR/ or $dnamut->region eq 'exon' ) {
    if ($dnamut->region eq 'exon' ) { # mRNA affected
	$seqDiff->rna_offset($rna->start_exon->phase -1);
	# new method into Bio::Ensembl::Transcript
	my $rna_pos = $rna->rna_pos($snp->start); 
	$rnachange = Bio::Variation::RNAChange->new
	    (-start => $rna_pos - $seqDiff->rna_offset, 
	     -end =>  $rna_pos - $seqDiff->rna_offset,
	     );
	$rnachange->length(1);
	$rnachange->mut_number(1);
	$seqDiff->add_Variant($rnachange);
	$dnamut->RNAChange($rnachange);
	$rnachange->DNAMutation($dnamut);
	$rnachange->proof('computed');
	
	$rnachange->allele_ori($dnaA1);
	foreach my $alleleseq (@alleles) {
	    my $A2 = Bio::Variation::Allele->new;
	    $A2->seq($alleleseq);
	    $rnachange->add_Allele($A2);
	}
	$rnachange->codon_pos(($rnachange->start -1 )% 3 +1);
	if ($rna_pos < 25 ) {
	    $rnachange->upStreamSeq($dnamut->upStreamSeq);
	} else {
	    $rnachange->upStreamSeq
		(lc substr($seqDiff->rna_ori, $rna_pos -25, 25));
	}    
	if ($rna_pos > $seqDiff->cds_end - 25 ) {
	    $rnachange->dnStreamSeq($dnamut->dnStreamSeq);
	} else {
	    $rnachange->dnStreamSeq
		(lc substr($seqDiff->rna_ori, $rna_pos + 1, 25));
	}
	my $ref_allele = lc substr($seqDiff->rna_ori, $rna_pos,1);
	$dnaA1->seq ne  $ref_allele && 
	    $self->warn("Found RNA ref allele: $ref_allele!");
    }      
    #
    # Protein level
    #
    if ($dnamut->region eq 'exon' ) { # coding region affected
	
	my $aachange = Bio::Variation::AAChange->new
	    (-start => (int($rnachange->start / 3 + 1))
	     );
	$aachange->end($aachange->start);
	$aachange->proof('computed');
	$seqDiff->add_Variant($aachange);
	$rnachange->AAChange($aachange);
	$aachange->RNAChange($rnachange);
	$aachange->mut_number(1);
	
	my $ct = new Bio::Tools::CodonTable;
	my $aa_allele_ori = $ct->translate($rnachange->codon_ori);
	my $aa_o = Bio::Variation::Allele->new;
	$aa_o->seq($aa_allele_ori) if $aa_allele_ori;
	$aachange->allele_ori($aa_o);
	
	my $aa_allele_mut = $ct->translate($rnachange->codon_mut);
	my $aa_m = Bio::Variation::Allele->new;
	$aa_m->seq($aa_allele_mut) if $aa_allele_mut;
	$aachange->add_Allele($aa_m);
	
	my $aa_length_ori = CORE::length($aa_allele_ori);
	$aachange->length($aa_length_ori);
	$aachange->end($aachange->start + $aa_length_ori - 1 );
	
	#terminator codon?
	
	my $ref_allele =  substr($aaseq->seq, $aachange->start -1 ,1);
	$aa_allele_ori ne  $ref_allele && 
	    $self->warn ("Found AA ref allele '$ref_allele' when expected to see $aa_allele_ori");
    }
    return $seqDiff;
}

1;
