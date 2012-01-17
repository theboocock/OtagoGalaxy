## Bioperl Test Harness Script for Modules
##
# CVS Version
# $Id: genesnp.t,v 1.2 2001-07-09 15:14:37 heikki Exp $

# Before `make install' is performed this script should be runnable with
# `make test' or 'perl -w t/test.t'. 
#After `make install' it should work as `perl test.t'
#use Carp;
use Test;
## We start with some black magic to preset the number of tests we are going to run
BEGIN { plan tests => 5 }  

use lib 't';
use EnsTestDB;
use Bio::EnsEMBL::ExternalData::GeneSNP;
use Bio::EnsEMBL::DBSQL::Gene_Obj;
ok(1);  # 1st test passes.
    
my $ens_test = EnsTestDB->new();
    
# Load some data into the db
$ens_test->do_sql_file("t/genetype.dump");
    
# Get an EnsEMBL db object for the test db
my $db = $ens_test->get_DBSQL_Obj;
ok($db);

my $gene_obj = new Bio::EnsEMBL::DBSQL::Gene_Obj($db);
my $gene = $gene_obj->get('ENSG00000003941');  
#my $gene=$db->get_Gene('ENSG00000003941');
ok $gene;

my $contig=$db->get_Contig('AB000381.00001');
#print $contig->id, "\n";
#print $contig->primary_seq->seq;

my @genes=$contig->get_Genes_by_Type('ensembl');
ok (scalar @genes !=0);

print "Genes: ", scalar @genes, "\n";
################### describe gene ##################################
#print STDERR 'gene: ', $gene->start, "\n";
my @transcripts = $gene->each_Transcript();
print "Transcripts: ", scalar @transcripts, "\n";
my $rna = pop @transcripts;

my @exons = $rna->each_Exon;
print "Exons: ", scalar @exons, "\n";
my $count = 0;
foreach my $exon ($rna->each_Exon) {
    print "Exon $count: ", $exon->id, ", ", $exon->start, ", ", $exon->end, ", ", 
    $exon->phase,", ", $exon->strand,  "\n";
    $count++;
}

my $seq = $rna->dna_seq;
print STDERR $seq->seq, "\n";
my $aa = $rna->translation;
print $aa->id, ", ", $aa->start, ", ", $aa->end, "\n";
my $aaseq = $rna->translate;
print STDERR $aaseq->seq, "\n";
#$contigseqobj = $contig->primary_seq;
print "\n\n";
#####################################################

use strict;
use Bio::EnsEMBL::ExternalData::Variation;
use Bio::Annotation::DBLink;
use Bio::Variation::IO;

my ($loc, $all);
#$loc = 28171; $all = 'T|A';#5'upstream
#$loc = 28175; $all = 'G|A';#5'untranslated pos -3
#$loc = 28177; $all = 'T|A';#5'UTR pos -1
#$loc = 28181; $all = 'G|A';#coding region pos 4, exon 1
$loc = 28269; $all = 'G|A';#coding region pos 28269, exon 1 (-2 from intron)

#$loc = 28182; $all = 'G|A';#coding region pos 5, exon 1
#$loc = 28183; $all = 'C|A';#coding region pos 5, exon 1
#$loc = 28277; #intron 1
#$loc = 28999; #intron 2
#$loc = 34296; $all = 'A|C';#coding region pos ?, exon 3


my $snp = Bio::EnsEMBL::ExternalData::Variation->new 
    (
     -id=> 'snp1',
     -seqname=> 'xx',
     -start=> $loc,
     -end=> $loc,
     -strand=> '1',
     -source_tag=> 'myInvention',
     -score=> '1',
     -status=> 'proven',
     -upStreamSeq=> 'AGGCTCCTGCGTGAAGTGATGCTCC',
     -alleles=> $all,
     -dnStreamSeq=> 'AGGCTCCTGCGTGAAGTGATGCTCC',
     );

my $link1 = new Bio::Annotation::DBLink;
$link1->database('dbSNP');
$link1->primary_id('242');
$snp->add_DBLink($link1);


my $genesnp = new Bio::EnsEMBL::ExternalData::GeneSNP
    (-gene=>$gene,
     -contig=>$contig);
my @vars = $genesnp->snp2gene($snp);

foreach  my $var ( @vars) {
    my $out = Bio::Variation::IO->newFh( '-FORMAT' => 'flat');
    #my $out = Bio::Variation::IO->newFh( '-FORMAT' => 'xml');
    $var && print $out $var;   
    $var && print  $var->alignment;
}

my @snps = ($snp, $snp);
@vars = $genesnp->snps2gene(@snps);
ok scalar @vars == 2;

# test cases where strand = -1!



