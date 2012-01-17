#!/usr/local/bin/perl
$|=1;
use POSIX;
$i=0;

open (FILE,$ARGV[0]);
while (<FILE>)
	{
	
	/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
	if ($1 ne $2)
	{
	push(@{$hash{$1}},"$2\t$3\t$4");
	$proteinhash{$1}=1;
	$proteinhash{$2}=1;
	}
	$j++;
	

	if (substr($j,-3,3) eq '000')
		{
		print "$j\n";
		}
	}

print "Creating Index File\n";
open (INDEX,">proteins.index");
foreach $protein (sort(keys(%proteinhash)))
{
print INDEX "$i\t$protein\n";
$proteinhash{$protein}=$i;
$i++;
}
close (INDEX);
print "Total Proteins: $i\n";

open (OUT,">proteins.mci");

print OUT "\(mclheader\n";
print OUT "mcltype matrix\n";
print OUT "dimensions $i","x","$i\n";
print OUT "\)\n\n";
print OUT "\(mclmatrix\nbegin\n";

print "Building Matrix\n";
foreach $protein (sort keys(%proteinhash))
{


print OUT "$proteinhash{$protein} ";
undef(%hithash);
foreach $hit (@{$hash{$protein}})
	{
	@array=split(" ",$hit);
	$evalue=$array[1]*(pow(10,-$array[2]));
	$evalue=-log10($evalue);

	if ($hithash{$proteinhash{$array[0]}} eq '')
		{
	$hithash{$proteinhash{$array[0]}}=$evalue;
		}
	}

foreach $hit (sort sorter(keys(%hithash)))
	{
	print OUT "$hit:$hithash{$hit} ";
	}
print OUT "\$\n";
}

print OUT "\)\n";
close (OUT);

sub sorter {($a <=> $b)}
