=head2 DESCRIPTION

This test covers the following DAS conversions:
  ensembl_peptide -> chromosome 36
  chromosome 36   -> ensembl_peptide
  ensembl_gene    -> ensembl_peptide
  toplevel        -> ensembl_peptide

=cut
use strict;

BEGIN { $| = 1;
	use Test::More tests => 5+(5*4);
}

use Bio::EnsEMBL::ExternalData::DAS::Coordinator;
use Bio::EnsEMBL::Feature;
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
my $pea = $dba->get_TranslationAdaptor();
my $tra = $dba->get_TranscriptAdaptor();
my $tran = $tra->fetch_by_translation_stable_id('ENSP00000324984');
my $gene = $gea->fetch_by_translation_stable_id('ENSP00000324984');
$tran = $tran->transfer($sla->fetch_by_gene_stable_id($gene->stable_id)); # reverse transcript on a forward strand regional slice
$gene = $gene->transfer($sla->fetch_by_gene_stable_id($gene->stable_id)); # reverse gene on a forward strand regional slice
my $prot = $tran->translation;

my $chro_cs = $tran->slice->coord_system;
my $topl_cs = $dba->get_CoordSystemAdaptor()->fetch_by_name('toplevel');
my $prot_cs = Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new( -name => 'ensembl_peptide' );
my $gene_cs = Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new( -name => 'ensembl_gene' );

is($gene->slice->strand,  1, "test gene correct slice strand");
is($gene->strand,        -1, "test gene correct strand");
is($gene->start,          1, "test gene correct start");
is($tran->slice->strand,  1, "test transcript correct slice strand");
is($tran->strand,        -1, "test transcript correct strand");

my $desc = 'peptide->chromosome';
my $c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
my $segments = $c->_get_Segments($prot_cs, $chro_cs, $tran->slice, undef, undef);
ok((grep {$_ eq $prot->stable_id} @$segments), "$desc correct query segment");
SKIP: {
my $q_feat = &build_feat($prot->stable_id, 1, 10);
my $f = $c->map_Features([$q_feat], $prot_cs, $chro_cs, $tran->slice)->[0];
ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
my $c = Bio::EnsEMBL::Feature->new(-slice=>$tran->slice, -start=>$tran->coding_region_end-29, -end=>$tran->coding_region_end, -strand=>$tran->strand);# coding region
is($f->seq_region_start,  $c->seq_region_start,  "$desc correct start");
is($f->seq_region_end,    $c->seq_region_end,    "$desc correct end");
is($f->seq_region_strand, $c->seq_region_strand, "$desc correct strand");
}

$desc = 'chromosome->peptide';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
$segments = $c->_get_Segments($chro_cs, $prot_cs, undef, undef, $prot);
is_deeply($segments, [sprintf '%s:%s,%s', $tran->seq_region_name,
                              $tran->seq_region_start,
                              $tran->seq_region_end],
                      "$desc correct query segment");
SKIP: {
my $q_start = $tran->coding_region_end-30 + $tran->slice->start;
my $q_end   = $tran->coding_region_end-1  + $tran->slice->start;
my $q_feat = &build_feat($tran->seq_region_name, $q_start, $q_end, $tran->strand); # the 'rightmost' genomic position is the 'leftmost' peptide position
my $f = $c->map_Features([$q_feat], $chro_cs, $prot_cs, undef)->[0];
ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
is($f->start,  1 , "$desc correct start");
is($f->end,    10, "$desc correct end");
is($f->strand, 1 , "$desc correct strand");
}

$desc = 'gene->peptide';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
$segments = $c->_get_Segments($gene_cs, $prot_cs, undef, undef, $prot);
is_deeply($segments, [$gene->stable_id], "$desc correct query segment");
SKIP: {
my $q_start = $gene->end - $tran->coding_region_end + 1;
my $q_end   = $q_start + 29;
my $q_feat = &build_feat($gene->stable_id, $q_start, $q_end, 1); # the 'rightmost' genomic position is the 'leftmost' peptide position
my $f = $c->map_Features([$q_feat], $gene_cs, $prot_cs, undef)->[0];
ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
is($f->start,  1 , "$desc correct start");
is($f->end,    10, "$desc correct end");
is($f->strand, 1 , "$desc correct strand");
}

$desc = 'toplevel->peptide';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
$segments = $c->_get_Segments($topl_cs, $prot_cs, undef, undef, $prot);
is_deeply($segments, [sprintf '%s:%s,%s', $tran->seq_region_name,
                              $tran->seq_region_start,
                              $tran->seq_region_end],
                      "$desc correct query segment");
SKIP: {
my $q_start = $tran->coding_region_end-30 + $tran->slice->start;
my $q_end   = $tran->coding_region_end-1  + $tran->slice->start;
my $q_feat = &build_feat($tran->seq_region_name, $q_start, $q_end, $tran->strand); # the 'rightmost' genomic position is the 'leftmost' peptide position
my $f = $c->map_Features([$q_feat], $topl_cs, $prot_cs, undef)->[0];
ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
is($f->start,  1 , "$desc correct start");
is($f->end,    10, "$desc correct end");
is($f->strand, 1 , "$desc correct strand");
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