=head2 DESCRIPTION

This test covers the following DAS conversions:
  chromosome 36 -> contig
  contig        -> chromosome 36
  chromosome 35 -> chromosome 36
  toplevel      -> chromosome 36
  toplevel      -> contig (not supported)

=cut

use strict;

BEGIN { $| = 1;
	use Test::More tests => 59;
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

use Bio::EnsEMBL::Utils::Exception qw(verbose);
verbose('EXCEPTION'); # we are deliberately instigating warnings

my $sla = $dba->get_SliceAdaptor();
my $csa = $dba->get_CoordSystemAdaptor();
my $chro_cs = $csa->fetch_by_name('chromosome', 'NCBI36');
my $cont_cs = $csa->fetch_by_name('contig');
my $ch35_cs = $csa->fetch_by_name('chromosome', 'NCBI35');
my $topl_cs = $csa->fetch_by_name('toplevel');
# contig:
my $cont1 = $sla->fetch_by_region('contig',     'AC126176.5.1.23501',   1,    21561, -1); # this contig aligns on reverse strand
my $cont2 = $sla->fetch_by_region('contig',     'AC090000.17.1.173552', 2054, 173552, 1);
my $cont3 = $sla->fetch_by_region('contig',     'AC084364.20.1.104791', 1952, 104791, 1);
# NCBI36:
my $chro1 = $sla->fetch_by_region('chromosome', '12', 102217673, 102239233, 1, 'NCBI36');
my $chro2 = $sla->fetch_by_region('chromosome', '12', 102239234, 102410732, 1, 'NCBI36');
my $chro3 = $sla->fetch_by_region('chromosome', '12', 102410733, 102513572, 1, 'NCBI36');
my $chro_all = $sla->fetch_by_region('chromosome', '12', 102217673, 102513572, 1, 'NCBI36');
# NCBI35:
my $ch351 = $sla->fetch_by_region('chromosome', '12', 102196010, 102217570, 1, 'NCBI35');
my $ch352 = $sla->fetch_by_region('chromosome', '12', 102217571, 102389069, 1, 'NCBI35');
my $ch353 = $sla->fetch_by_region('chromosome', '12', 102389070, 102491909, 1, 'NCBI35');
my $ch35_all = $sla->fetch_by_region('chromosome', '12', 102196010, 102491909, 1, 'NCBI35');
my @pairs = (
             [ $cont1, $chro1, $ch351 ],
             [ $cont2, $chro2, $ch352 ],
             [ $cont3, $chro3, $ch353 ],
            );

my $desc = 'chromosome->contig';
my $c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
for (@pairs) {
  my ($cont, $chro) = @$_;
  my $desc2 = "$desc ".$cont->seq_region_name;
  my $segments = $c->_get_Segments($chro_cs, $cont_cs, $cont);
  ok(grep ((sprintf "%s:%s,%s", $chro->seq_region_name, $chro->start, $chro->end), @$segments), "$desc2 correct query segment");
  SKIP: {
    my $q_feat = &build_feat($chro->seq_region_name, $chro->end-9, $chro->end, 1); # the 'rightmost' chromosomal position
    my $f = $c->map_Features([$q_feat], $chro_cs, $cont_cs, $cont)->[0];
    ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
    my $corr_start = $cont->strand == -1 ? $cont->start   : $cont->end-9;
    my $corr_end   = $cont->strand == -1 ? $cont->start+9 : $cont->end;
    is($f->seq_region_start,  $corr_start,   "$desc2 correct start");
    is($f->seq_region_end,    $corr_end,     "$desc2 correct end");
    is($f->seq_region_strand, $cont->strand, "$desc2 correct strand");
  };
}

$desc = 'contig->chromosome';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
my $segments = $c->_get_Segments($cont_cs, $chro_cs, $chro_all);
for (@pairs) {
  my ($cont, $chro) = @$_;
  my $desc2 = "$desc ".$cont->seq_region_name;
  ok(grep ((sprintf "%s:%s,%s", $cont->seq_region_name, $cont->start, $cont->end), @$segments), "$desc2 correct query segment");
  SKIP: {
    my $q_feat = &build_feat($cont->seq_region_name, $cont->end-9, $cont->end, 1); # the 'rightmost' contig position
    my $f = $c->map_Features([$q_feat], $cont_cs, $chro_cs, $chro_all)->[0];
    ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
    my $corr_start = $cont->strand == -1 ? $chro->start   : $chro->end-9;
    my $corr_end   = $cont->strand == -1 ? $chro->start+9 : $chro->end;
    is($f->seq_region_start,  $corr_start,   "$desc2 correct start");
    is($f->seq_region_end,    $corr_end,     "$desc2 correct end");
    is($f->seq_region_strand, $cont->strand, "$desc2 correct strand");
  };
}

$desc = 'chromosome35->chromosome36';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
$segments = $c->_get_Segments($ch35_cs, $chro_cs, $chro_all);
is_deeply($segments, [sprintf "%s:%s,%s", $ch35_all->seq_region_name, $ch35_all->start, $ch35_all->end], "$desc correct query segments");
for (@pairs) {
  my ($cont, $chro, $ch35) = @$_;
  my $desc2 = "$desc ".$cont->seq_region_name;
  SKIP: {
    my $q_feat = &build_feat($ch35->seq_region_name, $ch35->end-9, $ch35->end, 1); # the 'rightmost' chromosome35 position
    my $f = $c->map_Features([$q_feat], $ch35_cs, $chro_cs, $chro_all)->[0];
    ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
    my $corr_start = $chro->end-9;
    my $corr_end   = $chro->end;
    is($f->seq_region_start,  $corr_start, "$desc2 correct start");
    is($f->seq_region_end,    $corr_end,   "$desc2 correct end");
    is($f->seq_region_strand, 1,           "$desc2 correct strand");
  };
}

$desc = 'toplevel->chromosome36';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
for (@pairs) {
  my ($cont, $chro) = @$_;
  my $desc2 = "$desc ".$cont->seq_region_name;
  my $segments = $c->_get_Segments($topl_cs, $chro_cs, $chro);
  ok(grep ((sprintf "%s:%s,%s", $chro->seq_region_name, $chro->start, $chro->end), @$segments), "$desc2 correct query segment");
  SKIP: {
    my $q_feat = &build_feat($chro->seq_region_name, $chro->end-9, $chro->end, 1); # the 'rightmost' chromosomal position
    my $f = $c->map_Features([$q_feat], $topl_cs, $chro_cs, $chro_all)->[0];
    ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
    is($f->seq_region_start,  $chro->end-9, "$desc2 correct start");
    is($f->seq_region_end,    $chro->end,   "$desc2 correct end");
    is($f->seq_region_strand, 1,            "$desc2 correct strand");
  };
}

$desc = 'toplevel->contig';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
for (@pairs[0 .. 0]) {
  my ($cont, $chro) = @$_;
  my $desc2 = "$desc ".$cont->seq_region_name;
  my $segments = $c->_get_Segments($topl_cs, $cont_cs, $cont);
  ok(!@$segments, "$desc2 no query segments (not supported)");
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