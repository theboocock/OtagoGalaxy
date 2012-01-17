## Bioperl Test Harness Script for Modules
## $Id: SNPSQL.t,v 1.15 2001-07-09 15:14:37 heikki Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

#-----------------------------------------------------------------------
## perl test harness expects the following output syntax only!
## 1..3
## ok 1  [not ok 1 (if test fails)]
## 2..3
## ok 2  [not ok 2 (if test fails)]
## 3..3
## ok 3  [not ok 3 (if test fails)]
##
## etc. etc. etc. (continue on for each tested function in the .t file)
#-----------------------------------------------------------------------


## We start with some black magic to print on failure.
BEGIN { $| = 1; print "1..7\n"; 
	use vars qw($loaded); }
END {print "not ok 1\n" unless $loaded;}

#use lib '../';

use Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::Variation;

$loaded = 1;
print "ok 1\n";    # 1st test passes.


## End of black magic.
##
## Insert additional test code below but remember to change
## the print "1..x\n" in the BEGIN block to reflect the
## total number of tests that will be run. 

#creating the object
$snpdb = Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor->new( -dbname=>'snp_chr22', 
						       -user=>'root',
						       -host=>'localhost'

						       );

print "ok 2\n"; 

#doing a query
my $query =  qq{ select(2+3) };
my $sth = $snpdb->prepare($query);
my $res = $sth->execute();

if( $res) {
    print "ok 3\n"; 
} else {
   print "not ok 3\n";
}

while( (my $arr = $sth->fetchrow_arrayref()) ) {   
    my ($val) = @{$arr};
    
    if( $val == 5 ) {
	print "ok 4\n"; 
    } else {
	print "not ok 4\n";
    }
}

#using the method get_Ensembl_SeqFeatures_clone

#if ($snpdb->can(get_Ensembl_SeqFeatures_contig)) {
#
#    #AL136106" and p1.version = "2" ##AC025148.1 AB000381.1  AB012922.1
#    #get_Ensembl_SeqFeatures_clone(AC025148.1, 1 ,$start,$end); AL136106', '2'
#    @variations = $snpdb->get_Ensembl_SeqFeatures_contig('NT_011520', 21 );
#    if ( scalar @variations > 1 ) { 
#	 print "ok 5\n"; 
#    }  else {
#	 print "not ok 5\n";
#	 print STDERR "  Query returned ",  scalar @variations, " variations\n";
#    }
#
#    #$v = $variations[0];
#    if (ref $variations[0] eq 'Bio::EnsEMBL::ExternalData::Variation') {
#	 print "ok 6\n"; 
#    } else {
#	 print "not ok 6\n"; 
#    }
#
#
#} else { #using the method get_Ensembl_SeqFeatures_contig

   #AL136106" and p1.version = "2" ##AC025148.1 AB000381.1  AB012922.1
    #get_Ensembl_SeqFeatures_clone(AC025148.1, 1 ,$start,$end); AL136106', '2'
    @variations = $snpdb->get_Ensembl_SeqFeatures_clone('AC002472', 6 );
    if ( scalar @variations > 1 ) { 
	print "ok 5\n"; 
    }  else {
	print "not ok 5\n";
	print STDERR "  Query returned ",  scalar @variations, " variations\n";
    }

    #$v = $variations[0];
    if (ref $variations[0] eq 'Bio::EnsEMBL::ExternalData::Variation') {
	print "ok 6\n"; 
    } else {
	print "not ok 6\n"; 
    }
 
#}

#
# using the method get_SeqFeature_by_id 
#my $id = "677"; 
my $id = "782"; 
my @snps = $snpdb->get_SeqFeature_by_id($id);
my $snp = pop @snps;

if( $id eq $snp->id) {
    print "ok 7\n"; 
} else {
    print "not ok 7\n";
}

if ($snp->each_DBLink == 2 ) {
    print "ok 8\n"; 
} else {
    print "not ok 8\n";
    print STDERR "  Found ",  scalar $snp->each_DBLink , " DBLinks\n";
}

# using the method get_SeqFeature_by_id with dbSNP id
#my $id2 = "20409"; 
#my $snp = $snpdb->get_SeqFeature_by_id($id2); 
#if( $id eq $snp->id) {
#    print "ok 8\n"; 
#} else {
#    print "not ok 8\n";
#}



