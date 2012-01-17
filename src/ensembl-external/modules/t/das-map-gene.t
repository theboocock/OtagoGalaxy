=head2 DESCRIPTION

This test covers the following DAS conversions:
  ensembl_gene -> chromosome 36

=cut
use strict;

BEGIN { $| = 1;
	use Test::More tests => 3*2 + 5*2;
}

use Bio::EnsEMBL::ExternalData::DAS::Coordinator;
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

my $sla = $dba->get_SliceAdaptor();
my $gea = $dba->get_GeneAdaptor();
my $gene1 = $gea->fetch_by_translation_stable_id('ENSP00000324984');            # gene on a forward strand full slice
my $gene2 = $gene1->transfer($sla->fetch_by_gene_stable_id($gene1->stable_id)); # gene on a forward strand regional slice
my $gene3 = $gene1->transfer($gene1->feature_Slice);                            # gene on a reverse strand regional slice
my $chro_cs = $gene1->slice->coord_system;
my $gene_cs = Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new( -name =>'ensembl_gene' );

# Don't really want to use this slice, could take a while to get all the genes
#is($gene1->slice->strand,  1, "test gene 1 correct slice strand");
#is($gene1->strand,        -1, "test gene 1 correct strand");
#is($gene1->start,  $gene1->seq_region_start, "test gene 1 correct start");

is($gene2->slice->strand,  1, "test gene 2 correct slice strand");
is($gene2->strand,        -1, "test gene 2 correct strand");
is($gene2->start,          1, "test gene 2 correct start");

is($gene3->slice->strand, -1, "test gene 3 correct slice strand");
is($gene3->strand,         1, "test gene 3 correct strand");
is($gene3->start,          1, "test gene 3 correct start");

my $desc = 'gene->chromosome';
my $c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
for my $gene ($gene2, $gene3) {
  my $segments = $c->_get_Segments($gene_cs, $chro_cs, $gene->slice, undef, undef);
  ok((grep {$_ eq $gene->stable_id} @$segments), "$desc correct query segment");
  my $q_feat = &build_feat($gene->stable_id, 1, 10);
  SKIP: {
  my $f = $c->map_Features([$q_feat], $gene_cs, $chro_cs, $gene->slice)->[0];
  ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
  is($f->seq_region_start,  $gene->seq_region_end-9,  "$desc correct start");
  is($f->seq_region_end,    $gene->seq_region_end,    "$desc correct end");
  is($f->seq_region_strand, $gene->seq_region_strand, "$desc correct strand");
  }
}

sub build_feat {
  my ($segid, $start, $end, $strand ) = @_;
  return {
    'segment_id'  => $segid,
    'start'       => $start,
    'end'         => $end,
    'orientation' => defined $strand && $strand == -1 ? '-' : '+',
  };
}