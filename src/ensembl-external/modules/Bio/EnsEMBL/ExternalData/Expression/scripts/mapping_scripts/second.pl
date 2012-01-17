use strict;

my $enst2unigene="input_data/new_ELUS_ENSUjoiner.dat";
my $trans_gene_translation="input_data/transcript_gene_translation.dat";
my $out=">input_data/final_joiner.dat";

open (FH,$trans_gene_translation) || die "cant open $trans_gene_translation";

my %ensembl;
while (<FH>){

    chomp;
    my ($enst,$ensg,$ensp)=split(/\t/);

    $ensembl{$enst}->{ensg}=$ensg;
    $ensembl{$enst}->{ensp}=$ensp;

}


open (UNI,$enst2unigene) || die "cant open $enst2unigene";
open (OUT,$out) || die "cant open $out";
while (<UNI>){

 my ($enst,$uni,$tag)=split(/\t/);

 print OUT $enst,"\t",$ensembl{$enst}->{ensg},"\t",$ensembl{$enst}->{ensp},"\t",$uni,"\t",$tag;


}


print STDERR "printed output to $out\n";
