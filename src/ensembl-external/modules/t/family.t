# $Id: family.t,v 1.17 2002-10-31 17:14:48 abel Exp $

# testing of family database.

## We start with some black magic to print on failure.
use strict;
BEGIN {
    eval { require Test; };
    if( $@ ) { 
	use lib 't';
    }
    use Test;
    use vars qw($NTESTS);
    $NTESTS = 30;
    plan tests => $NTESTS;
}




#BEGIN { $| = 1; print "1..13\n";
#	use vars qw($loaded); }

#END {print "not ok 1\n" unless $loaded;}

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::Family::DBSQL::FamilyAdaptor;
use Bio::EnsEMBL::ExternalData::Family::Family;
#use lib '../../ensembl/modules/t';
use lib 't';
use EnsTestDB;

END {     
    for ( $Test::ntest..$NTESTS ) {
	skip("Could not get past module loading, skipping test",1);
    }
}

#test 1
ok(1);

## configuration thing. Note: EnsTestDB.conf is always read (if available); this
## hash only overrides bits and pieces of that.
my $testconf={
	'schema_sql' => ['../sql/family.sql'],
	'module' => 'Bio::EnsEMBL::ExternalData::Family::DBSQL::DBAdaptor',
	'user' => 'ensadmin',
	'pass' => 'ensembl'
};
    
my $testdb = EnsTestDB->new($testconf);

# Load some data into the db

$testdb->do_sql_file("t/family.dump");
# $testdb->pause;

my $db = $testdb->get_DBSQL_Obj;

my $famad = $db->get_FamilyAdaptor;

#test 2
ok(1);

my @expected = qw(ENSEMBLPEP ENSEMBLGENE SPTR);

my %dbs=undef;
foreach my $ex (@expected) {
    $dbs{$ex}++;
}

my @found = @{$famad->known_databases};
#test 3
ok $found[0],'ENSEMBLGENE',"Unexpected db in database";
#test 4
ok $found[1],'ENSEMBLPEP',"Unexpected db in database";
#test 5
ok $found[2],'SPTR',"Unexpected db in database";


my $id= 'ENSF00000000002';
my $fam = $famad->fetch_by_stable_id($id);
#test 6
ok $fam->isa('Bio::EnsEMBL::ExternalData::Family::Family'),1,"Did not find family $id";
#test 7
ok $fam->size,4,"Got unexpected family size";
#test 8
ok $fam->size_by_dbname('ENSEMBLGENE'),3,"Unexpected family size by database name";
#test 9
ok $fam->size_by_dbname_taxon('ENSEMBLGENE',9606),2,"Unexpected family size by database name";


my $got = length($fam->get_alignment_string());
my $expected = 1911;
#test 10
ok $got == $expected, 1, "expected alignment length $expected, got $got";

## now same for one without an alignment; should fail gracefully
$id= 'ENSF00000000005';
my $ali;
eval {
    $ali=$famad->fetch_by_stable_id($id)->get_alignment_string();
};

#test 11
ok $@ || defined($ali),'',"got: $@ and/or $ali";

#test 12
ok $fam->isa('Bio::EnsEMBL::ExternalData::Family::Family'),1,"Could not fetch family $id";

# not finding given family should fail gracefully:
$id= 'all your base are belong to us';
eval { 
    $fam = $famad->fetch_by_stable_id($id);
};
$@ || $fam,'',"got: $@ and/or $fam\n";

my @pair = ('SPTR', 'O15520');
my @fam = @{$famad->fetch_by_dbname_id(@pair)};

#test 13
ok $fam[0]->isa('Bio::EnsEMBL::ExternalData::Family::Family'),1,"Could not fetch family for @pair";
my $id = $famad->store($fam[0]);
#test 14
ok $id,4,"Tried to store existing family, and did not get correct dbid back";
$fam[0]->stable_id('test');
foreach my $member (@{$fam[0]->get_all_members}) {
  $member->stable_id($member->stable_id."_test");
}

$famad->store($fam[0]);
my $fam = $famad->fetch_by_stable_id('test');

#test 15
ok $fam->size_by_dbname('ENSEMBLPEP'),18,"Got wrong size for specific database";

$id = 'growth factor';
my @fams = @{$famad->fetch_by_description_with_wildcards($id,1)};
$expected = 6;
#test 16
ok @fams == $expected,1,"expected $expected families, found ".int(@fams);

$id='fgf 21';
@fams = $famad->fetch_by_description_with_wildcards($id);
$expected = 1;

#test 17
ok @fams == $expected,1,"expected $expected families, found ".int(@fams);

# Test general SQL stuff:
$expected = 11;
my $q=$famad->prepare("select count(*) from family");
$q->execute();
my ( $row ) = $q->fetchrow_arrayref;

#test 18
ok (defined($row) && int(@$row) == 1 && $$row[0] eq $expected),1,"Something wrong at SQL level";

my $memberad = $db->get_FamilyMemberAdaptor;
my @member = @{$memberad->fetch_by_stable_id("ENSG000001101002")};

#test 19
ok $member[0]->taxon->genus,"Homo","Should have get Homo";

my $taxonad = $db->get_TaxonAdaptor;
my $taxon = $taxonad->fetch_by_dbID(9606);
$taxon->taxon_id(3000);
#test 20
ok $taxonad->store($taxon),3000,"store species failed";

#test21
@fam = @{$famad->fetch_by_dbname_taxon_member('ENSEMBLGENE',9606,'ENSG000001101002')};
ok $fam[0]->dbID,1,"not the good family picked up\n";

#test 22
ok $fam[0]->stable_id,"ENSF00000000001","Not the good family stable_id\n";

#test 23->25
ok @{$fam[0]->get_members_by_dbname('SPTR')},2,"Not the good number of SPTR";
ok @{$fam[0]->get_members_by_dbname('ENSEMBLGENE')},2,"Not the good number of ENSEMBLGENE";
ok @{$fam[0]->get_members_by_dbname('ENSEMBLPEP')},2,"Not the good number of ENSEMBLPEP";

#test 26->30
ok @{$fam[0]->get_members_by_dbname_taxon('SPTR',0)},2,"Not the good number of SPTR taxon:0";
ok @{$fam[0]->get_members_by_dbname_taxon('ENSEMBLGENE',9606)},1,"Not the good number of ENSEMBLGENE taxon:9606";
ok @{$fam[0]->get_members_by_dbname_taxon('ENSEMBLGENE',10090)},1,"Not the good number of ENSEMBLGENE taxon:10090";
ok @{$fam[0]->get_members_by_dbname_taxon('ENSEMBLPEP',9606)},1,"Not the good number of ENSEMBLPEP taxon:9606";
ok @{$fam[0]->get_members_by_dbname_taxon('ENSEMBLPEP',10090)},1,"Not the good number of ENSEMBLPEP taxon:10090";