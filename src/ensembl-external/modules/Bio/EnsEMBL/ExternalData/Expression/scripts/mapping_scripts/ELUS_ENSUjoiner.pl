use strict;
my $counter = 0;


my $known_file="ELUSmapper.dat";
my $all_file="ENSUpostprocessor.dat";
my $temp_file=">ELUS_ENSUjoiner.dat";


my %known_hash;
open(TEMP,$temp_file) || die "cant open $temp_file";
open (ELUS, $known_file) || die "cannot open $known_file";
while (<ELUS>)
{
    chomp;
    my ($enst, $locuslink, $unigene, $tag) = split /\t/;          
    $known_hash{$enst}=$unigene;
    print TEMP "$enst\t$unigene\n";

}
close ELUS; 


open (ENSU, $all_file) || die "cannot open $all_file\n";
while (<ENSU>)  
      {
      chomp;
      my ($enst, $unigene, $score) = split /\t/;
   
      if (exists $known_hash{$enst}){
	  next; 
     }else {
	  print TEMP "$enst\t$unigene\n";
      }
  }
close ENSU;







































