=head2 DESCRIPTION

This test covers the following DAS conversions:
  ipi_peptide -> ensembl_peptide
  ipi_peptide -> chromosome

=cut
use strict;

BEGIN { $| = 1;
	use Test::More tests => 10;
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

my $pea = $dba->get_TranslationAdaptor();
my $tra = $dba->get_TranscriptAdaptor();
my $sla = $dba->get_SliceAdaptor();
my $prot = $pea->fetch_by_stable_id('ENSP00000324984');
my $tran = $tra->fetch_by_translation_stable_id($prot->stable_id);
my $chro = $sla->fetch_by_transcript_stable_id($tran->stable_id);
$tran = $tran->transfer($chro);

my ($xref) = grep {$_->primary_id eq 'IPI00294828'} @{ $tran->get_all_DBLinks('IPI') };
my $prot_cs = Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new( -name => 'ensembl_peptide' );
my $xref_cs = Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new( -name => 'ipi_acc' );
my $chro_cs = $chro->coord_system;

my $desc = 'ipi->peptide';
my $c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
my $segments = $c->_get_Segments($xref_cs, $prot_cs, undef, undef, $prot);
ok((grep {$_ eq $xref->primary_id} @$segments), "$desc correct query segment");
SKIP: {
my $q_start = $xref->query_start;
my $q_end   = $xref->query_start + 9;
my $q_feat = &build_feat($xref->primary_id, $q_start, $q_end);
my $f = $c->map_Features([$q_feat], $xref_cs, $prot_cs, undef)->[0];
ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
my $c_start = $xref->translation_start;
my $c_end   = $xref->translation_start + 9;
is($f->start,  $c_start,  "$desc correct start");
is($f->end,    $c_end,    "$desc correct end");
is($f->strand, 1,         "$desc correct strand");
}

$desc = 'ipi->chromosome';
$c = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new();
$segments = $c->_get_Segments($xref_cs, $chro_cs, $chro, undef, undef);
ok((grep {$_ eq $xref->primary_id} @$segments), "$desc correct query segment");
SKIP: {
my $q_start = $xref->query_start;
my $q_end   = $xref->query_start + 9;
my $q_feat = &build_feat($xref->primary_id, $q_start, $q_end);
my $f = $c->map_Features([$q_feat], $xref_cs, $chro_cs, $chro)->[0];
ok($f, "$desc got mapped feature") || skip('requires mapped feature', 3);
my $tr_mapper = Bio::EnsEMBL::TranscriptMapper->new($tran);
my ($c) = $tr_mapper->pep2genomic($xref->translation_start, $xref->translation_start+9);
is($f->start,  $c->start,  "$desc correct start");
is($f->end,    $c->end,    "$desc correct end");
is($f->strand, $c->strand, "$desc correct strand");
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