#ENST00000000027 1636
#ENST00000000089 5563
#ENST00000000233 381
#ENST00000000273 60312
#ENST00000000289 2672  

#unigene_locuslink.dat 
#2       10
#4       125
#11      1084
#12      1089
#21      1990 

use strict;
use English;

my $counter;

open (EL, "enst_locuslink.dat") || die "cant open enst_locuslink.dat\n";
while (<EL>)  {
      chomp;
      my ($locuslink1, $ensembl) = split /\t/;
      print STDERR $counter++, "\t", $ensembl, "\n";
      open (UL, "unigene_locuslink.dat") || die "cant open unigene_locuslink.dat";
      while (<UL>)
	{
        chomp;
        my ($unigene1, $locuslink2) = split /\t/;
        if ($locuslink1 eq $locuslink2)
	   { 
           print "$ensembl\t$locuslink1\t$unigene1\n"; 
           }        
        }
      close UL;
} 

