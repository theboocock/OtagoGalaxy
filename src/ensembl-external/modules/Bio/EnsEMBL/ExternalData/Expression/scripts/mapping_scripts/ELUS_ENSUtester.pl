#
# this is a quality control script
#
# usage perl ELUS_ENSUtester.pl how_many_to_compare
#
#

use strict;
use English;

my $counter = 0;
my $positive = 0;
my $all = 0;

open (ENSU, ENSUmapper.dat) || die "cannot open ENSUmapper.dat\n";
while (<ENSU>)  
      {
      $all++;
      chomp;
      my ($enst, $unigene, $score) = split /\t/;
      $unigene =~ s/unigene Hs.//;
      #$unigene_line =~ m/(Hs.\d+)/;
      #my $unigene = $1;
      #print "heyhey $unigene\n";
      open (ELUS, "ELUSmapper.dat") || die "cannot open ELUSmapper.dat\n";
      while (<ELUS>)
	{
        chomp;
        my ($enst2, $locuslink, $unigene2, $tag) = split /\t/;
        if ($enst2 eq $enst) 
           {
           if ($unigene eq $unigene2) {$positive++}
else {#print  "$enst $unigene $unigene2 \n";
}
           $counter++;
           last;
           }
        }
      close ELUS; 
      last if $all == $ARGV[0]; 
      }
close ENSU; 
print "all: $all, known: $counter, known_correct $positive\n";

