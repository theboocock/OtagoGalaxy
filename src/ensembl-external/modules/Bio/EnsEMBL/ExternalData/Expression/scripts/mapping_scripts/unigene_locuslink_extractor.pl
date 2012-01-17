


#extracts unigene_locuslink mapping from the NCBI's Hs.all file



while (<>)
{
chomp;
if (/ID\s+Hs.(\d+)/) {print "\n", $1, "\t"}
if (/LOCUSLINK\s+(\d+)/) {print $1}
}
