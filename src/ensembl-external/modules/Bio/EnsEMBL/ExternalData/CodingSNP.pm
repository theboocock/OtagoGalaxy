
#
# BioPerl module for CodingSNP
#
# Cared for by Emmanuel mongin heikki <>
#
# Copyright Emmanuel mongin heikki
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

CodingSNP - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::EnsEMBL::ExternalData::CodingSNP;
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

    my ($gene, $transcript, $exonstruct, $snpstruct) =
	    $self->_rearrange([qw(GENE
				  TRANSCRIPT
				  EXON_STRUCT
				  SNP_STRUCT
				)],@args);
    $gene && $self->gene($gene);
    $transcript && $self->transcript($transcript);
    $exonstruct && $self->exon_struct($exonstruct);
    $snpstruct && $self->snp_struct($snpstruct);
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

=head2 exon_struct

 Title   : exon_struct
 Usage   : $obj->exon_struct($newval)
 Function: 
 Returns : value of exon_struct
 Args    : newvalue (optional)


=cut

sub exon_struct{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'exon_struct'} = $value;
    }
    return $obj->{'exon_struct'};

}


=head2 snp_struct

 Title   : snp_struct
 Usage   : $obj->snp_struct($newval)
 Function: 
 Returns : value of snp_struct
 Args    : newvalue (optional)


=cut

sub snp_struct{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'snp_struct'} = $value;
    }
    return $obj->{'snp_struct'};

}


sub snp2gene {
    my ($self, $snp) = @_;
    my $seqDiff = undef;

    $self->gene || $self->throw("Set gene to a Bio::EnsEMBL::Gene object");
    
    my @seqDiffs = ();
    foreach my $trans ($self->gene->each_Transcript) {
	#print STDERR $trans->id,"\n";
	#print STDERR $rna->dna_seq->seq, "\n";
	my $aa = $trans->translation; #Bio::Ensembl::Translation object
	#print $aa->id, ", ", $aa->start, ", ", $aa->end, "\n";
	my $aaseq = $trans->translate;
	#print STDERR $aaseq->seq, "\n";
	
	$seqDiff = $self->_calculate_gene_coordinates($snp, $trans, $aa, $aaseq);
	$seqDiff && push @seqDiffs, $seqDiff;
    }
    return @seqDiffs;
}


=head2 snp2transcript

 Title   : snp2transcript
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub snp2transcript{
   my ($self,$snp) = @_;
   my $seqDiff = undef;
   $self->transcript || $self->throw("Set transcript to a Bio::EnsEMBL::Transcript object");
   
   my $trans = $self->transcript;

   my $aa = $trans->translation; #Bio::Ensembl::Translation object
   use Data::Dumper;
   print Dumper($aa);
   my $aaseq = $trans->translate;
   $seqDiff = $self->_calculate_gene_coordinates($snp, $trans, $aa, $aaseq);
   return $seqDiff;
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
    $seqDiff->moltype('rna');
    $seqDiff->numbering('entry');
    #$seqDiff->dna_ori(); leave undefined, 
    #we do not want to burden the object with long contig sequnce
    $seqDiff->rna_ori($rna->dna_seq->seq);
    $seqDiff->aa_ori($rna->translate); #slow opeation?
    $seqDiff->id($rna->id);
    $seqDiff->rna_id($rna->id);
    $seqDiff->offset($aa->start -1);
    $seqDiff->cds_end($aa->end - $aa->start + 1);
    
    print STDERR "AA: ".$aa->start."\t".$aa->end."\n";


##################################
#Do some kind of dirty stuff...don't want to know about it.  
##################################
    
    my $snp_ref = $self->snp_struct;
    my %snps = %$snp_ref;

    my $ex_str = $self->exon_struct;
    my %exons = %$ex_str;

    my @ex_obj = $rna->each_Exon;
    
    my @ex_array;

    foreach my $e(@ex_obj) {
	push(@ex_array,$exons{$e->id});
    }

#Here we get the position of the SNP in what we could call DNA coordinates
    my $start_pos = $snps{$snp->id}->{'start'};
    
    my $ex_st = $ex_array[0]->{'start'};

    my $dna_pos = abs($start_pos - $ex_st + 1);
    
#Lets get the position of the SNP in transcript coordinates
    my $snp_ex = $snps{$snp->id}->{'exon'};
    my $ex_rank = $exons{$snp_ex}->{'rank'};
    my $ex_array = $ex_rank -1;
    
    
    my $count = 0;
    my $tr_length = 0;
    while ($count < ($ex_rank-1)) {
	my $length = abs($ex_array[$count]->{'end'} - $ex_array[$count]->{'start'} + 1);
	$tr_length = $tr_length + $length;
	$count++;
    }
    my $length1 =  abs($ex_array[$ex_array]->{'start'} - $start_pos + 1);
    $tr_length = $tr_length + $length1;
    #print STDERR "TR POS: $tr_length\n";
####################################
    
    #
    # DNA level
    #

    my $dna_start = $dna_pos - $seqDiff->offset;
    #my $dna_start = $snps{$snp->id}->{'start'} - $seqDiff->offset;
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
    
#Now it would be nice to get the postion of the SNP in transcript coordinates...joy of conversions...

    $dnamut->upStreamSeq
	(lc substr($rna->dna_seq->seq, $tr_length -25, 25));
    $dnamut->dnStreamSeq
	(lc substr($rna->dna_seq->seq, $tr_length +1, 25));


    my $ref_allele;# = lc substr($self->contig->primary_seq->seq, $snp->start, 1 );
    $dnaA1->seq ne $ref_allele &&
	$self->warn("Found DNA ref allele: $ref_allele!");

#what if the SNP is closer to either end than 25 nt?

    #Lets say that we only have exonic SNPs
		
	
    $dnamut->region('exon');

#WHAT SHOULD I DO WITH THAT?????

    #$dnamut->region_value($exon->id. " ($exoncount)");
		

    #
    # RNA level
    #

    my $rnachange = undef;
    #if ($dnamut->region =~ /UTR/ or $dnamut->region eq 'exon' ) {
    if ($dnamut->region eq 'exon' ) { # mRNA affected

#Check exactly what its doing...
	$seqDiff->rna_offset($rna->start_exon->phase -1);

	#print STDERR "OFFSET: ".$seqDiff->rna_offset."\n";
	# new method into Bio::Ensembl::Transcript
	# we shouldn't need this method here
	#my $rna_pos = $rna->rna_pos($snp->start); 
	
	my $rna_pos = $tr_length;
	#print STDERR "RNA $rna_pos\n";
	#print STDERR "RNAPOS: $pos\n";
	#$rnachange = Bio::Variation::RNAChange->new
	#    (-start => $rna_pos - $seqDiff->rna_offset, 
	#     -end =>  $rna_pos - $seqDiff->rna_offset,
	#     );
	#print STDERR "HERE1\n";
	$rnachange = Bio::Variation::RNAChange->new
	    (-start => $rna_pos - $seqDiff->rna_offset, 
	     -end =>  $rna_pos - $seqDiff->rna_offset,
	     );
	#print STDERR "HERE2\n";
	$rnachange->length(1);
	$rnachange->mut_number(1);
	$seqDiff->add_Variant($rnachange);
	$dnamut->RNAChange($rnachange);
	$rnachange->DNAMutation($dnamut);
	$rnachange->proof('computed');
	$rnachange->region('coding');
	

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

    #print STDERR $rnachange->upStreamSeq, "\n";

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

	print STDERR "ORI: ".$rnachange->codon_ori, "\n";

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

