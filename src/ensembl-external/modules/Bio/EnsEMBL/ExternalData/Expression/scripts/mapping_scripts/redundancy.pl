
my %hash = ();

while (<>)
{
chomp; 
my ($enst, $unigene) = split /\t/;
push (@{$hash{$unigene}}, $enst);
}



my %hash2 = ();
foreach my $key (keys %hash) {
$hash2{$key} = scalar (@{$hash{$key}});  #size of the table
#print "aaaa$hash2{$key}\n";
} 

my %hash3 = (); 

foreach my $key2 (keys %hash2) {
print $key2, "\t", $hash2{$key2}, "\n";
$hash3{$hash2{$key2}}++;
}

foreach my $key3 (sort {$a<=>$b} keys %hash3) {
print $key3, "\t", $hash3{$key3}, "\n";
}


                                                    

