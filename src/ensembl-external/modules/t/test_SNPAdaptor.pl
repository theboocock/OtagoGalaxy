#! /usr/local/ensembl/bin/perl

use strict;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Variation;
use Bio::EnsEMBL::ExternalData::Population;
use Bio::EnsEMBL::ExternalData::Frequency;
use Bio::EnsEMBL::SNP;
use Bio::EnsEMBL::Utils::Eprof qw( eprof_start eprof_end);
use Bio::EnsEMBL::External::ExternalFeatureAdaptor;

use vars '@ISA';

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor Bio::EnsEMBL::External::ExternalFeatureAdaptor );

my $user = 'ensro';
my $host = 'ecs2';
my $port = 3364;
my $snp_port = 3361;
#my $snp_db = "homo_sapiens_snp_22_34d";
my $snp_db = "snp_test";
my $core_db = "homo_sapiens_core_22_34d";

my $coredb = new Bio::EnsEMBL::DBSQL::DBAdaptor (
						 -user =>$user,
						 -host =>$host,
						 -port =>$port,
						 -dbname => $core_db,
						);

my $snpdb = new Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor (
							    -user =>$user,
							    -host =>$host,
							    -port =>$snp_port,
							    -dbname => $snp_db,
							   );

#my $refsnp_id = $ARGV[0];
my $ssid = $ARGV[0];

my $db_snp = $snpdb->get_SNPAdaptor;

#my $snp = $db_snp->fetch_attributes_only($refsnp_id);

#print "SNP_dbID : ",$snp->dbID,"\n";
#print "SNP_source : ",$snp->source_tag(),"\n";
#print "SNP_source_version : ",  $snp->source_version(),"\n";
#print "SNP_status : ",  $snp->status(),"\n";
#print "SNP_alleles : ",  $snp->alleles(),"\n";
#print "SNP_upStreamSeq : ",  $snp->upStreamSeq(),"\n";
#print "SNP_dnStreamSeq : ",  $snp->dnStreamSeq(),"\n";
#print "SNP_mapweight : ",  $snp->score(),"\n"; 
#print "SNP_het : ",  $snp->het(),"\n";
#print "SNP_hetse : ",  $snp->hetse(),"\n";
#print "SNP_hapmap : ",  $snp->hapmap_snp(),"\n";

my $slice = $coredb->get_SliceAdaptor->fetch_by_region('chromosome', 'X');

my $slice_strand = $db_snp->fetch_slice_strand_by_ssid($ssid,$slice);

print "slice_strand is $slice_strand\n";
