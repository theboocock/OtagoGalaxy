## Bioperl Test Harness Script for Modules
##
# CVS Version
# $Id: local_dx.t,v 1.1 2000-10-05 21:36:27 stajich Exp $


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'


## We start with some black magic to print on failure.
BEGIN { $| = 1; print "1..8\n"; 
	use vars qw($loaded $DEBUG); }
END {print "not ok 1\n" unless $loaded;}

use strict;
use lib 't';
use Bio::EnsEMBL::Map::DBSQL::Obj;
use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::ExternalData::Disease::DBHandler;

use EnsTestDB;
$loaded = 1;
$DEBUG=1;
print "ok 1\n";    # 1st test passes.


my $ens_test_dx = EnsTestDB->new(-module=>'Bio::EnsEMBL::ExternalData::Disease::DBHandler', -schema_sql=>["../sql/disease.sql"]);
$ens_test_dx->do_sql_file('t/dxdb.dump');
print "ok 2\n";

my $ens_test_map = EnsTestDB->new(-schema_sql=>["../../ensembl-map/sql/table.sql"],
				  -module=>'Bio::EnsEMBL::Map::DBSQL::Obj');
#ens_test_map->do_sql_file('t/map.dump');
print "ok 3\n";
my $ens_test_db = EnsTestDB->new(-schema_sql=>['../../ensembl/sql/table.sql']);
$ens_test_db->do_sql_file('../../ensembl/modules/t/db.dump');
print "ok 4\n";

# Get an EnsEMBL db object for the test db
my $db = $ens_test_db->get_DBSQL_Obj;
my $mapdb = $ens_test_map->get_DBSQL_Obj;
print "ok 5\n";    

my $module = 'Bio::EnsEMBL::ExternalData::Disease::DBHandler';
my $diseasedb = new $module( -dbname=>$ens_test_dx->dbname(),
			     -host=>$ens_test_dx->host(),
			     -ensdb=>$db,
			     -user=>$ens_test_dx->user(),
			     -pass=>$ens_test_dx->password(),
			     -mapdb=>$mapdb);
print "ok 6\n";
my @diseases=$diseasedb->all_diseases(10,1);
print "ok 7\n";

foreach my $dis ( @diseases ) 
{
    print STDERR $dis->name,"\n" if ( $DEBUG );

    foreach my $location($dis->each_Location) {
	
	print STDERR "has gene ",$location->external_gene," on chromosome ",
	$location->chromosome," (",$location->cyto_start,"-",$location->cyto_end,")","\n" if ( $DEBUG );
	
	if (defined $location->ensembl_gene){	    
	    print STDERR $dis->name," ",$location->external_gene," = ",$location->ensembl_gene->id,"\n" if( $DEBUG );
	}
	else {print STDERR "no ensembl predictions for ", $location->external_gene,"\n" if ( $DEBUG );}
    }
}
print "ok 8\n";










