#!/usr/bin/perl
# Murray Cadzow 22.11.11
# reads vcf file line by line and writes out lines that have "." as ID
# takes vcf file as input and writes to inputfile_novel-snps.vcf or
# the output file specified

use strict; use warnings;
use Getopt::Std;
use vars qw($opt_h $opt_v $opt_f $opt_i $opt_o);
our $opt_i;
our $opt_o;
getopts('hfvi:o:');

my $usage = "
usage: getopt.pl [options] <arguments...>
options:
-h help
-v version
-i <input_filename.vcf>
-o <output_filename.vcf>
-f full list is just printed, not novel snp which is default
if -o is not given input_filename-novel.vcf will be created
";

if ($opt_h){
    print $usage;
    exit;
}

if ($opt_v){
    print("get_snps.pl Version 1.0\n");
}
if($opt_f){
    if($opt_i){
        open(IN, "$opt_i") or die "error reading $opt_i for reading";

        if($opt_o){
            open(OUT, ">$opt_o") or die "error creating $opt_o"; #write to file specified
        } else { #else create input_filename-novel.vcf
            open(OUT, ">$opt_i-novel_snps.vcf") #creates $opt_i-novel_snps.vcf
                or die "error creating $opt_i-novel_snps.vcf";
        }
#read each line in
        while(my $line = <IN>){
            print(OUT "$line");
        }

        close IN;
        close OUT;
    }
} elsif ($opt_i){
#open file to read
    open(IN, "$opt_i") or die "error reading $opt_i for reading";
    if($opt_o){
        open(OUT, ">$opt_o") or die "error creating $opt_o"; #write to file specified
    } else { #else create input_filename-novel.vcf
        open(OUT, ">$opt_i-novel_snps.vcf") #creates $opt_i-novel_snps.vcf
            or die "error creating $opt_i-novel_snps.vcf";
    }
#read each line in
    while(my $line = <IN>){
#write out if starts with '#'
        if( $line =~ m/^#/ ){
            print(OUT "$line");
        } elsif($line =~ m/^\w+\t\w+\t\.\t.\t\.\t./){
            #Do nothing fix for murray
#look at 3rd column (ID), write out if == "."
        }elsif ($line =~ m/^\w+\t\w+\t\.\t./){
                print(OUT "$line");
            }
        }
    close IN;
    close OUT;
}

exit 0
