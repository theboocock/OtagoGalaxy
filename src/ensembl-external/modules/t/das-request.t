=head2 DESCRIPTION

This test covers a basic DAS request

=cut

use strict;

BEGIN { $| = 1;
	use Test::More tests => 4;
}

use Bio::EnsEMBL::ExternalData::DAS::Coordinator;
use Bio::EnsEMBL::ExternalData::DAS::Source;

# TODO: need to use data from a test database!
#use Bio::EnsEMBL::Test::MultiTestDB;
#use Bio::EnsEMBL::Test::TestUtils;
#my $multi = Bio::EnsEMBL::Test::MultiTestDB->new();
#my $dba = $multi->get_DBAdaptor( 'core' );
use Bio::EnsEMBL::Registry;
Bio::EnsEMBL::Registry->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous',
);
my $dba = Bio::EnsEMBL::Registry->get_DBAdaptor( 'human', 'core' ) || die("Can't connect to database");
my $csa = $dba->get_CoordSystemAdaptor();
my $chro_cs = $csa->fetch_by_name('chromosome', 'NCBI36');

my $source = Bio::EnsEMBL::ExternalData::DAS::Source->new(
  -url => 'http://www.ebi.ac.uk/das-srv/genomicdas/das',
  -dsn => 'astd_exon_human_36',
  -coords => [ $chro_cs ],
);

my $c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new(
  -sources => [ $source ],
);

my $sla = $dba->get_SliceAdaptor();
my $slice = $sla->fetch_by_region('chromosome', '12', 102200000, 102300000, 1, 'NCBI36');

my $struct;
$struct   = $c->fetch_Features($slice);
&test('basic request');
$struct   = $c->fetch_Features($slice, 'group' => 'TRAN00000078556');
&test('group filter');
$struct   = $c->fetch_Features($slice, 'group' => 'TRAN00000078556', 'type' => 'exon:coding:ASTD');
&test('group and type filters');
$struct   = $c->fetch_Features($slice, 'group' => 'TRAN00000078556', 'type' => 'exon:coding:ASTD', 'feature' => 'EXON00000501265');
&test('group, type and feature ID filters');

sub test {
  # LOGIC_NAME => 'features' => ARRAY
  my @features = @{ $struct->{$source->logic_name}->{'features'} };
  ok( scalar @features, shift ) || diag 'source returned '.scalar @features.' features';
}