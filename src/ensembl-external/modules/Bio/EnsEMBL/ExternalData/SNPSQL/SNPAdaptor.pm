# EnsEMBL Gene reading writing adaptor for mySQL
#
# Copyright EMBL-EBI 2002
#
# Author: Heikki Lehvaslaiho
# 
# Date : 09.08.2002
#

=head1 NAME

Bio::EnsEMBL::ExternalData::SNPSQL::SNPAdaptor

=head1 SYNOPSIS

A SNP adaptor which sits over a SNP database.  Provides a means of getting
SNPs out of a SNP database as Bio::EnsEMBL::ExternalData::Variation objects. 

=head1 CONTACT

Post questions to the EnsEMBL developer list: <ensembl-dev@ebi.ac.uk> 

=head1 APPENDIX

=cut

use strict;

package Bio::EnsEMBL::ExternalData::SNPSQL::SNPAdaptor;

use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Variation;
use Bio::EnsEMBL::ExternalData::Population;
use Bio::EnsEMBL::ExternalData::Frequency;
use Bio::EnsEMBL::SNP;
use Bio::EnsEMBL::Utils::Eprof qw( eprof_start eprof_end);
use Bio::EnsEMBL::External::ExternalFeatureAdaptor;

use vars '@ISA';

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor Bio::EnsEMBL::External::ExternalFeatureAdaptor );

=head2 fetch_attributes_only

  Arg [1]    : int refsnp_id
  Arg [2]    : (optional) string source
  Example    : none
  Description: Retrieves a snp objcet from the SNP database but does not
               populate the location information.  This is necessary given 
               the current state of the snp database because location 
               information has to be retrieved differently for different 
               species!
  Returntype : Bio::EnsEMBL::SNP
  Exceptions : none
  Caller     : snpview

=cut

sub fetch_attributes_only{
  my $self = shift;

  my $refsnp_id = shift;
  my $source = shift || 'dbSNP';

  my $sth = $self->prepare('
      SELECT refsnp.internal_id, refsnp.snpclass,  refsnp.snptype,
	     refsnp.observed, refsnp.seq5, refsnp.seq3,
             refsnp.het, refsnp.hetse, refsnp.validated, refsnp.mapweight, refsnp.hapmap_snp,
             ds.version
      FROM   RefSNP refsnp, DataSource ds
      WHERE  refsnp.id = ?
      AND    ds.id = refsnp.datasource
      AND    ds.datasource = ?');

  $sth->execute("$refsnp_id", $source);

  $sth->rows || $self->throw("snp with refsnp_id/src [$refsnp_id/$source]" .
			     "not found in database");

  my ($dbID, $snp_class, $snp_type, $alleles, $seq5, $seq3,
      $het, $hetse, $confirmed, $mapweight, $hapmap_snp, $source_version) = $sth->fetchrow_array;

  $sth->finish;

  # use the right vocabulary for the SNP status
  if ($confirmed eq 'no-info') {
    $confirmed = "suspected";
  } else {
    $confirmed =~ s/-/ /;
    $confirmed = "proven $confirmed";
  }

  # the allele separator should be  '|'
  $alleles =~ s/\//\|/g;

  #prune flank sequences to 25 nt
  $seq5 = substr($seq5, -25, 25);
  $seq3 = substr($seq3, 0, 25);
    
  #add Ns to length of 25;
  $seq3 .= 'N' x ( 25 - length $seq3 ) if length($seq3) < 25 ;
  $seq5 = ('N' x ( 25 - length $seq5 ) ). $seq5 if length($seq5) < 25 ;


my $snp = Bio::EnsEMBL::SNP->new;

  $snp->dbID($dbID);
  $snp->source_tag($source);
  $snp->source_version($source_version);
  $snp->status($confirmed);
  $snp->alleles($alleles);
  $snp->upStreamSeq($seq5);
  $snp->dnStreamSeq($seq3);
  $snp->score($mapweight); 
  $snp->het($het);
  $snp->hetse($hetse);
  $snp->hapmap_snp($hapmap_snp);

  #DBLink
  my $link = new Bio::Annotation::DBLink;
  $link->database('dbSNP');
  $link->primary_id($refsnp_id);
  $snp->add_DBLink($link);
    
  #get alternative IDs
  $sth = $self->prepare("	    
	  SELECT subsnp.handle, subsnp.altid 
	  FROM   SubSNP as subsnp
	  WHERE  subsnp.internal_id = ?");
  
  $sth->execute($dbID);
  
  while(my ($handle, $altid) = $sth->fetchrow_array) {
    my $link = new Bio::Annotation::DBLink;
    $link->database($handle);
    $link->primary_id($altid);
    #add dbXref to Variation
    $snp->add_DBLink($link);
  }
    # Add Genotypes (Variation objects) to the SNP
    # fc1 & jws 2004
  eval {
    foreach my $genotype (@{$self->fetch_genotype_by_SNP_id($snp->id)}){
      $snp->add_genotype($genotype);
    }
  };


  # Add Population and Frequency (allele frequency) objects to the SNP
  foreach my $pop (@{$self->fetch_pops_by_SNP_id($snp->id)}) {
    my $freqs = undef;
    eval {
      $freqs = $self->fetch_freqs_by_pop_SNP_id($pop->pop_id, $snp->id);
    };
    next if $@;
    next unless @$freqs;

    foreach my $freq (@$freqs) {
      $pop->add_frequency($freq);
    }
    $snp->add_population($pop);
  }
  return $snp;
 }

=head2 fetch_by_SNP_id

  Arg [1]    : int $refsnpid
               The refsnp identifier of the snp to retrieve
  Arg [2]    : string $source
               The source string of the snp to retrieve
  Example    : @snps = @{$snp_adaptor->fetch_by_SNP_id($refsnpid, 'dbSNP')};
  Description: Retreives a snp via its refsnp identifier and
               datasource.  One variation object is returned per mapped 
               location of the snp.
  Returntype : Bio::EnsEMBL::Variation 
  Exceptions : none
  Caller     : internal

=cut

sub fetch_by_SNP_id {
  my ($self, $refsnpid, $source) = @_;
  
  unless($refsnpid && $source) {
    die("Both refsnpid and source arguments are required");
  }

  my $sth = $self->prepare('
      SELECT STRAIGHT_JOIN 
             refsnp.internal_id, refsnp.id, hit.acc, hit.version, hit.start, 
             hit.end, hit.type, hit.strand, refsnp.snpclass,  refsnp.snptype,
	     refsnp.observed, refsnp.seq5, refsnp.seq3,
             refsnp.het, refsnp.hetse, refsnp.validated, refsnp.mapweight,
             ds.datasource
      FROM   RefSNP refsnp, DataSource ds left join Hit hit on hit.internal_id = refsnp.internal_id
     WHERE   ds.id = refsnp.datasource
      AND    refsnp.id = ? 
      AND    ds.datasource = ?');

  $sth->execute("$refsnpid", $source);

  $sth->rows || $self->throw("$source $refsnpid not in database or not mapped to contig");

  my $arr;
  my @variations = ();
  while ($arr = $sth->fetchrow_arrayref) { 
    my ($internal_id, $dbsnp_id, $acc, $ver, $begin, $end, $postype, 
	$strand, $class, $type, $alleles, $seq5, $seq3, $het, $hetse,  
	$confirmed, $mapweight, $source ) = @$arr;
    
    #snp info not valid
    $self->throw("SNP withdrawn. Reason: $type ") 
      if ($type && $type ne 'notwithdrawn');
    
    # use the right vocabulary for the SNP status
    if ($confirmed eq 'no-info') {
      $confirmed = "suspected";
    } else {
      $confirmed =~ s/-/ /;
      $confirmed = "proven $confirmed";
    }
    
    # the allele separator should be  '|'
    $alleles =~ s/\//\|/g;
    
    #prune flank sequences to 25 nt
    $seq5 = substr($seq5, -25, 25);
    $seq3 = substr($seq3, 0, 25);
    
    #add Ns to length of 25;
    $seq3 .= 'N' x ( 25 - length $seq3 ) if length($seq3) < 25 ;
    $seq5 = ('N' x ( 25 - length $seq5 ) ). $seq5 if length($seq5) < 25 ;
    
    #create output objects
    my $acc_version = '';
    $acc_version .= uc $acc if $acc;
    $acc_version .= ".$ver" if $ver;
  
    my $snp = new Bio::EnsEMBL::ExternalData::Variation;
    if ($acc_version) {
      $snp->seqname($acc_version);
      $snp->start($begin);
      $snp->end($end);
      $snp->strand($strand);
      $snp->original_strand($strand);
    }
    $snp->source_tag($source);
    $snp->status($confirmed);
    $snp->alleles($alleles);
    $snp->upStreamSeq($seq5);
    $snp->dnStreamSeq($seq3);
    $snp->score($mapweight); 
    $snp->het($het);
    $snp->hetse($hetse);

    
    #DBLink
    my $link = new Bio::Annotation::DBLink;
    $link->database('dbSNP');
    $link->primary_id($dbsnp_id);
    
    #add dbXref to Variation
    $snp->add_DBLink($link);
    
    #get alternative IDs
    my $sth2 = $self->prepare("	    
	  SELECT subsnp.handle, subsnp.altid 
	  FROM   SubSNP as subsnp
	  WHERE  subsnp.internal_id = ?");
    
    $sth2->execute($internal_id);
    
    while( (my $arr2 = $sth2->fetchrow_arrayref()) ) {
      my ($handle, $altid) = @{$arr2};
      
      my $link = new Bio::Annotation::DBLink;
      $link->database($handle);
      $link->primary_id($altid);
      
      #add dbXref to Variation
      $snp->add_DBLink($link);
    }
    push @variations, $snp;
  }
  return \@variations;
}

=head2 fetch_genotype_by_SNP_id

  Arg [1]    : int $refsnpid
               The refsnp identifier of the snp to retrieve genotypes
  Example    : @snps = @{$snp_adaptor->fetch_genotype_by_SNP_id($refsnpid)};
  Description: Retreives a variation object via its refsnp identifier 
               One variation object is returned for genotype data
               associated with that snp
  Returntype : Bio::EnsEMBL::Variation
  Exceptions : none
  Caller     : internal

=cut

sub fetch_genotype_by_SNP_id {

  my ($self, $refsnpid) = @_;
  my $sth = $self->prepare('
      SELECT refsnp.id, Strain.ssid, Strain.name, Strain.allele, 
             GTInd.sex, GTInd.source, GTInd.source_ind_id
      FROM   RefSNP refsnp, Strain Strain, GTInd GTInd
     WHERE   refsnp.internal_id = Strain.internal_id and Strain.ind_id = GTInd.ind_id
      AND    refsnp.id = ?');

  $sth->execute("$refsnpid") || $self->throw("$refsnpid not in database or don't have genotype data");

  my $arr;
  my @snps = ();
  while ($arr = $sth->fetchrow_arrayref) { 
    my ($refsnpid, $ssid, $strain_name, $strain_alleles, $sex, $gt_source, $gt_source_ind_id ) = @$arr;
    my $snp = new Bio::EnsEMBL::ExternalData::Variation;
    $snp->snpid($refsnpid);
    $snp->ssid($ssid);
    $snp->strain_name($strain_name);
    $snp->strain_alleles($strain_alleles);
    $snp->sex($sex);
    $snp->gt_source($gt_source);
    $snp->gt_source_ind_id($gt_source_ind_id);

    push @snps, $snp;
  }
  return \@snps;
}


=head2 fetch_pops_by_SNP_id

  Arg 1      : int $refsnpid
               Use refsnp identifier of the snp to retrieve the populations
               in which it has been genotyped.
  Example    : @pops = @{$snp_adaptor->fetch_pop_by_SNP_id($refsnpid)};
  Description: Retreives a population objects for a given refSNP id
  Returntype : Array ref of Bio::EnsEMBL::ExternalData::Population objects
  Exceptions : none
  Caller     : internal

=cut

sub fetch_pops_by_SNP_id {
  my ($self, $refsnpid) = @_;
  my $sth = $self->prepare('
      SELECT straight_join sp.id, sp.name, sp.class, sp.samplesize 
      FROM   RefSNP rs, SubSNP ss, SubPop sp 
      WHERE  rs.internal_id = ss.internal_id 
      AND    ss.id=sp.ssid 
      AND    sp.batchtype="ALE"   
      AND    rs.id = ?');

  $sth->execute($refsnpid) || $self->throw("$refsnpid not in database or don't have genotype data");

  my $arr;
  my @pops = ();
  while ($arr = $sth->fetchrow_arrayref) { 
    my ($pop_id, $name, $region, $sample_size) = @$arr;
    my $pop = new Bio::EnsEMBL::ExternalData::Population;

    $pop->pop_id($pop_id);
    $pop->name($name);
    $pop->region($region);
    $pop->sample_size($sample_size);
    push @pops, $pop;
  }
  return \@pops;
}


=head2 fetch_freqs_by_pop_SNP_id

  Arg 1      : int $refsnpid
  Arg 2      : int population ID
               Use refsnp identifier and population ID to retrieve the allele
               frequencies
  Example    : @freqs = @{$snp_adaptor->fetch_freqs_by_pop_SNP_id($pop_id,$refsnpid)};
  Description: Retreives frequency population objects for a given refSNP id
  Returntype : Array ref of Bio::EnsEMBL::ExternalData::Frequency objects
  Exceptions : none
  Caller     : internal

=cut

sub fetch_freqs_by_pop_SNP_id {
  my ($self, $pop_id, $refsnpid) = @_;

  my $sth = $self->prepare('
      SELECT straight_join f.snpallele, f.otherallele, f.freq, f.count, f.ssid, f.batchid 
      FROM   RefSNP rs, SubSNP ss, Freq f
      WHERE  rs.internal_id = ss.internal_id 
      AND    ss.id=f.ssid 
      AND    f.type="ALE" AND rs.id=? AND f.popid=?
      ORDER BY f.batchid;');

  $sth->execute($refsnpid, $pop_id);

  $sth->rows || $self->throw("$refsnpid not in database or don't have frequency data");

  my $arr;
  my @freqs = ();
  while ($arr = $sth->fetchrow_arrayref) { 
    my ($snpallele, $otherallele, $frequency, $count, $ssid,$batch_id) = @$arr;
    my $freq = new Bio::EnsEMBL::ExternalData::Frequency;
    my $allele = $snpallele || $otherallele;
    $freq->allele($allele);
    $freq->frequency($frequency);
    $freq->count($count);
    $freq->ssid($ssid);
    $freq->batch_id($batch_id);

    push @freqs, $freq;
  }
  return \@freqs;
}

=head2 fetch_slice_strand_by_ssid

  Arg 1      : int $ssid
  Arg 2      : $slice
               Use $ssid and $slice to retrieve the slice strand of
               given $ssid
  Example    : my $slice_strand = $snp_adaptor->fetch_slice_strand_by_ssid($ssid,$slice)
  Description: Retreives slice strand for a given SubSNP id
  Returntype : int $slice_strand
  Exceptions : none
  Caller     : internal

=cut

sub fetch_slice_strand_by_ssid {
  my ($self, $ssid, $slice) = @_;
  my $slice_name = $slice->name;
  my @names = split /\:/, $slice_name;
  my $slice_strand = $names[-1];
  my $sth = $self->prepare('
      SELECT ch.strand as ref_strand, ss.strand_to_rs as ss_strand
      FROM   ContigHit ch, SubSNP ss
      WHERE  ch.internal_id = ss.internal_id and ss.id = ?;');

  $sth->execute($ssid)|| $self->throw("The SubSNP table don't have strand_to_rs column?");

  my ($ref_strand, $ss_strand) = $sth->fetchrow;
  my $ssid_slice_strand = $slice_strand * $ref_strand * $ss_strand;

  return $ssid_slice_strand;
}

=head2 fetch_by_clone_accession_vesion

 Title   : fetch_by_clone_accession_version
 Usage   : fetch_by_clone_accession_version($embl_accession_number,
		  		          $sequence_version,$start,$end);
 Function:

    The semantics of this method is as follows:
    	$sequence_version - embl/genbank sequence version
    	$embl_accession_number - the embl/genbank accession number

    The $start/$end can be ignored, but methods can take advantage of it.
    This is so that ensembl can ask for features only on a region of DNA,
    and if desired, the external database can respond with features only
    in this region, rather than the entire sequence.

    The hope is that the second method could potentially have a very
    complex set of mappings of other embl_accession numbers to one
    embl_accession number and provide the complex mapping.

 Example :
 Returns : list of Bio::SeqFeature::Variation objects
 Args    : $embl_accession_number,
           $sequence_version,
           $start of range, optional
           $end of range, optional

=cut

sub fetch_by_clone_accession_version {
    my($self) = shift;
    my ($acc, $ver, $start, $stop) = @_;

    #lists of variations to be returned
    my @variations;

    #sanity checks

    if ( ! defined $acc) {
      $self->throw("Two arguments are requided: embl_accession number and version_number!");
    }
    if ( ! defined $ver) {
      $self->throw("Two arguments are required: embl_accession number and version_number!");
    }
    if (defined $start) {
      $start = 1 if $start eq "";
      if ( $start !~ /^\d+$/  and $start > 0) {
	$self->throw("$start is not a valid start");
      }
    }
    if (defined $stop) {
      $start = 1 if not defined $start;
      if ( $stop !~ /^\d+$/ and $stop > 0 ) {
	$self->throw("$stop is not a valid stop");
      }
    }
    if (defined $start and defined $stop) {
      if ($stop < $start) {
	$self->throw("$stop is smaller than $start not a valid start");
      }
    }
    
    my $acc_version = uc "$acc.$ver";
    

    # db query to return all variation information ; confidence attribute is gone!!
    my $query = qq{
		   SELECT  p1.start, p1.end, p1.type, p1.strand,
		   p2.id, p2.snpclass,  p2.snptype,
		   p2.observed, p2.seq5, p2.seq3,
		   p2.het, p2.hetse,
		   p2.validated, p2.mapweight, p3.datasource, p2.internal_id
		   FROM  Hit as p1,  RefSNP as p2, DataSource as p3 
		   WHERE  p1.acc = "$acc" and p1.version = "$ver"
		   AND p3.id = p2.datasource
		   AND p1.internal_id = p2.internal_id
		  };
    
    if($start) {
      $query .= " AND p1.start >= $start";
    } 
    if($stop) {
      $query .= " AND p1.end <= $stop";
    }

    my $sth = $self->prepare($query);
    my $res = $sth->execute();

    while( (my $arr = $sth->fetchrow_arrayref()) ) {

      
      my ($begin, $end, $hittype, $strand,
	  $snpuid, $class, $type,
	  $alleles, $seq5, $seq3, $het, $hetse,
	  $confirmed, $mapweight,
	  $source, $primid 
	 ) = @{$arr};
      
      #snp info not valid
      next if ($type && $type ne 'notwithdrawn');
      next if $mapweight > 2;
      

      #exclude SNPs outside the given $start-$end range
      if (defined $start) {
	next if $begin < $start;
      }
      if (defined $stop) {
	next if $end > $stop;
      }
      
      # use the right vocabulary for the SNP status
      if ($confirmed eq 'no-info') {
	$confirmed = "suspected";
      } else {
	$confirmed =~ s/-/ /;
	$confirmed = "proven $confirmed";
      }
      
      # the allele separator should be  '|'
      $alleles =~ s/\//\|/g;
      
      #prune flank sequences to 25 nt
      $seq5 = substr($seq5, -25, 25);
      $seq3 = substr($seq3, 0, 25);
      
      #add Ns to length of 25;
      $seq3 .= 'N' x ( 25 - length $seq3 ) if length($seq3) < 25 ;
      $seq5 = ('N' x ( 25 - length $seq5 ) ). $seq5 if length($seq5) < 25 ;
      
      #
      # prepare the output objects
      #
      
      #Variation
      my $snp = new Bio::EnsEMBL::ExternalData::Variation
	(-start => $begin,
	 -end => $end,
	 -strand => $strand,
	 -original_strand => $strand,
	 -source_tag => $source,
	 -score  => $mapweight,
	 -status => $confirmed,
	 -alleles => $alleles,
	);
      $snp->upStreamSeq($seq5);
      $snp->dnStreamSeq($seq3);
      $snp->het($het);
      $snp->hetse($hetse); 
      
      # set for compatibility to Virtual Contigs
      $snp->seqname($acc_version);

      #DBLink
      my $link = new Bio::Annotation::DBLink;
      $link->database('dbSNP');
      $link->primary_id($snpuid);
      $link->optional_id($acc_version);
      #add dbXref to Variation
      $snp->add_DBLink($link);
      
      #get alternative IDs
      my $query2 = qq{ 
		      SELECT p1.handle, p1.altid 
		      FROM   SubSNP as p1
		      WHERE  p1.internal_id = "$primid"
		     };

      my $sth2 = $self->prepare($query2);
      my $res2 = $sth2->execute();
      while( (my $arr2 = $sth2->fetchrow_arrayref()) ) {
	my ($handle, $altid) = @{$arr2};

	my $link = new Bio::Annotation::DBLink;

	$link->database($handle);
	$link->primary_id($altid);
	
	#add dbXref to Variation
	$snp->add_DBLink($link);
      }
      #add SNP to the list
      push(@variations, $snp);
    }

    return \@variations;
  }

sub fetch_all_by_Clone {
  my ( $self, $clone, $start, $end ) = @_;

  $self->fetch_by_clone_accession_version( $clone->embl_id(),
					   $clone->embl_version(),
					   $start,
					   $end);
}

sub coordinate_systems {
  return ("CLONE");
}

=head2 fetch_between_internal_ids

 Title   : fetch_between_internal_ids
 Usage   :
 Function:
 Example :
 Returns : a list of all snp info between start_internal_id and end_internal_id
 Args    : start_internal_id and end_internal_id
           
=cut

sub fetch_between_internal_ids {
  my ($self,$start_internal_id,$end_internal_id) = @_;
  my ($query, @var_objs, %var_objs);
  if (!$end_internal_id) {
    $end_internal_id = $start_internal_id;
  }
  
    $query = qq{
      SELECT r.id, r.snpclass, r.mapweight, r.observed, r.seq5, r.seq3, 
      h.acc, h.version, h.start, h.end, h.strand
	FROM   RefSNP as r left join Hit as h on r.internal_id = h.internal_id
	  WHERE snptype = "notwithdrawn" 
	    and r.internal_id between $start_internal_id and $end_internal_id
	  };
  
  my $sth=$self->prepare($query);
  
  my $res=$sth->execute();
  while (my $info = $sth->fetchrow_hashref()) {
    if ($info) {
      my $var_obj = $self->_objFromHashref($info);
      #$var_objs{$var_obj->snpid}=$var_obj;
      push (@var_objs, $var_obj);
    }
  }
  return \@var_objs;
}
 
  
=head2 fetch_all_by_Slice

 Title   : fetch_all_by_Slice
 Usage   : snpa->fetch_all_by_Slice($slice)
 Function: return variation objects in the given slice
 Example : snpa->fetch_all_by_Slice($slice)
 Returns : a list of all variation objects in the given slice
 Args    : $slice
           
=cut

sub fetch_all_by_Slice{
  my ($self,$slice) = @_;
  my ($query, @var_objs, %var_objs);
  my $chr_start = $slice->start;
  my $chr_end = $slice->end;
  my $chr_name = $slice->seq_region_name;
  
    $query = qq{
      SELECT r.id, r.snpclass, r.mapweight, r.observed, r.seq5, r.seq3,
      ch.physmap as start, ch.physmapstr as end , ch.physmapstrand as strand
	FROM   RefSNP as r, ContigHit as ch
	  WHERE  r.snptype = "notwithdrawn" 
	    and r.internal_id = ch.internal_id and ch.physmap between $chr_start and $chr_end
            and ch.chr = "$chr_name" 
	  };
  
  my $sth=$self->prepare($query);
  
  my $res=$sth->execute();
  while (my $info = $sth->fetchrow_hashref()) {
    if ($info) {
      my $physmapstr = $info->{end};
      my ($start, $end) = split /\^|\.\./, $physmapstr if ($info->{start} ne $info->{end});
      $info->{start} = $start-$chr_start+1 if ($start);
      $info->{end} = $end-$chr_start+1 if ($end);
      $info->{start} = $info->{start}-$chr_start+1 if (!$start);
      $info->{end} = $info->{end}-$chr_start+1 if (!$end);
      my $var_obj = $self->_objFromHashref($info);
      #$var_objs{$var_obj->snpid}=$var_obj;
      push (@var_objs, $var_obj);
    }
  }
  return \@var_objs;
}
 
=head2 fetch_genotyped_by_Slice

 Title   : fetch_genotyped_by_Slice
 Usage   : snpa->fetch_genotyped_by_Slice($slice)
 Function: return variation objects in the given slice that have been genotyped
 Example : snpa->fetch_genotyped_by_Slice($slice)
 Returns : a list of genotyped variation objects in the given slice
 Args    : $slice

=cut

sub fetch_genotyped_by_Slice{
  my ($self, $slice) = @_;
  warn ("ERROR:  No slice object passed to $0") if !$slice;
  my ($query, @var_objs, %var_objs);
  my $chr_start = $slice->start;
  my $chr_end = $slice->end;
  my $chr_name = $slice->seq_region_name;
  

#mysql> SELECT distinct(r.id), r.snpclass, r.mapweight, r.observed, r.seq5, r.seq3,ch.physmap as start, ch.physmapstr as end , ch.physmapstrand as strand FROM   RefSNP as r, ContigHit as ch, Strain as s WHERE  r.snptype = "notwithdrawn"  and r.internal_id = ch.internal_id and r.internal_id= s.internal_id  and ch.physmap between 11474465 and 11584465 and ch.chr = '11' and s.allele like "%/%";

    $query = qq{
      SELECT distinct(r.id), r.snpclass, r.mapweight, r.observed, r.seq5, 
      r.seq3, ch.physmap as start, ch.physmapstr as end,
      ch.physmapstrand as strand, r.internal_id as internal_id
      FROM   RefSNP as r, ContigHit as ch, Strain as s 
      WHERE  r.snptype = "notwithdrawn" 
            and r.internal_id =  s.internal_id 
            and r.internal_id = ch.internal_id 
            and s.allele != ""
            and ch.physmap between $chr_start 
            and $chr_end  and ch.chr = "$chr_name"
          };
  
  my $sth=$self->prepare($query);
  my $res=$sth->execute();
  while (my $info = $sth->fetchrow_hashref()) {
 if ($info) {
      my $physmapstr = $info->{end};
      my ($start, $end) = split /\^|\.\./, $physmapstr if ($info->{start} ne $info->{end});
      $info->{chr_start} = $start || $info->{start};
      $info->{start} = $start-$chr_start+1 if ($start);
      $info->{end} = $end-$chr_start+1 if ($end);
      $info->{start} = $info->{start}-$chr_start+1 if (!$start);
      $info->{end} = $info->{end}-$chr_start+1 if (!$end);
      my $var_obj = $self->_objFromHashref($info);
      #$var_objs{$var_obj->snpid}=$var_obj;
      push (@var_objs, $var_obj);
    }
  }
  return \@var_objs;
}


=head2 fetch_by_refsnpid

 Title   : fetch_by_refsnpid
 Usage   :
 Function:
 Example :
 Returns : a list of snp info by given refsnpid
 Args    : refsnpid, mouse_flag
           
=cut

sub fetch_by_refsnpid {

  my ($self,$refsnpid,$mouse) = @_;
  my (@infos,$query,%var_objs);
  
  if ($mouse) {
    $query = qq{
      SELECT t1.id, t1.snpclass, t1.snptype, t1.observed, t1.seq5, t1.seq3
	FROM   RefSNP as t1
	  WHERE  t1.id = "$refsnpid"
	};
  }
  else {
    $query = qq{
      SELECT t1.id, t1.snpclass, t1.snptype, t1.observed, t1.seq5, t1.seq3, 
      t2.acc, t2.version, t2.start, t2.end, t2.strand
	FROM   RefSNP as t1 left join Hit as t2 on t1.internal_id = t2.internal_id
	  WHERE t1.mapweight <=2 and t1.id = "$refsnpid"
	};
  }
		       
  my $sth=$self->prepare($query);
  
  my $res=$sth->execute();
  while (my $info = $sth->fetchrow_hashref()) {
    if ($info) {
      my $var_obj = $self->_objFromHashref($info);
      return $var_obj if $var_obj;
    }
  }
}

sub _objFromHashref {
  my ($self,$info) = @_;
  
  my $acc_version = '';
  my $acc = $info->{acc};
  my $ver = $info->{version};
  $acc_version .= uc $acc if $acc;
  $acc_version .= ".$ver" if $ver;
  
  my $snp = new Bio::EnsEMBL::ExternalData::Variation;
  
  $snp->acc($info->{acc});
  $snp->version($info->{version});
  $snp->seqname($acc_version);
  $snp->start($info->{start});
  $snp->end($info->{end});
  $snp->strand($info->{strand});
  $snp->source_tag('dbSNP');
  #$snp->status($info->{confirmed});
  $snp->alleles($info->{observed});
  $snp->upStreamSeq($info->{seq5});
  $snp->dnStreamSeq($info->{seq3});
  $snp->score($info->{mapweight}); 
  #$snp->het($info->{het});
  #$snp->hetse($info->{hetse});
  $snp->snpid($info->{id});
  $snp->snpclass($info->{snpclass});
  $snp->unique_id($info->{chr_start},$info->{internal_id});

  #DBLink
  my $link = new Bio::Annotation::DBLink;
  $link->database('dbSNP');
  $link->primary_id($info->{id});
  
  #add dbXref to Variation
  $snp->add_DBLink($link);
  
  return $snp;
}
  
1;
