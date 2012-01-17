use strict;


my $file="input_data/ELUS_ENSUjoiner.dat";
my $uni_map="input_data/SAGEmap_ug_tag-rel-Nla3-Hs";
my $out=">input_data/new_ELUS_ENSUjoiner.dat"; 

my %uni_hash;
open (MAP,$uni_map) || die "cant open $uni_map";

while (<MAP>){

    chomp;
    my ($uni,$description,$tag)=split(/\t/);

    push @{$uni_hash{$uni}},$tag;


}


open (JOIN,$file) || die "cant open $file";
open (OUT,$out) || die "cant open $out";

while (<JOIN>){ 
chomp;   
    my ($enst,$uni)=split(/\t/);
    
       foreach my $tag (@{$uni_hash{$uni}}){
	   print OUT $enst,"\t",$uni,"\t",$tag,"\n";
       } 
}   


print STDERR "printed output to $out\n";




