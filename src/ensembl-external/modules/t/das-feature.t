use strict;

BEGIN { $| = 1;
        use Test::More tests => 34;
}

use Bio::EnsEMBL::ExternalData::DAS::Feature;
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

my $slice = $dba->get_SliceAdaptor()->fetch_by_region('chromosome', 'X',1000,2000,1);

  my $raw_group = {
    'group_id'    => 'group1',
    'group_label' => 'Group 1',
    'group_type'  => 'transcript',
    'note'        => [ 'Something interesting' ],
    'link'        => [
                      { 'href' => 'http://...',
                        'txt'  => 'Group Link'  }
                     ],
    'target'      => [
                      { 'target_id'    => 'Seq 1',
                        'target_start' => '400',
                        'target_stop'  => '800'  }
                     ]
  };

  my $raw_feature = {
  
    # Core Ensembl attributes:
    'start'  => 100,
    'end'    => 200,
    'slice'  => $slice,
    'strand' => 1,
    
    # DAS-specific attributes:
    'orientation'   => '+',
    'feature_id'    => 'feature1',
    'feature_label' => 'Feature 1',
    'type'          => 'exon',
    'type_id'       => 'SO:0000147',
    'type_category' => 'inferred from electronic annotation (ECO:00000067)',
    'score'         => 85,
    'note'          => [ 'Something useful to know' ],
    'link'          => [
                        { 'href' => 'http://...',
                          'txt'  => 'Feature Link' }
                       ],
    'group'         => [
                        $raw_group
                       ],
    'target'        => [
                        { 'target_id'    => 'Seq 1',
                          'target_start' => '500',
                          'target_stop'  => '600'  }
                       ]
    
  };
  
  my $f = Bio::EnsEMBL::ExternalData::DAS::Feature->new( $raw_feature );
  &test();
  
  # test strand
  delete $raw_feature->{'strand'};
  $raw_feature->{'orientation'} = '+';
  $f = Bio::EnsEMBL::ExternalData::DAS::Feature->new( $raw_feature );
  ok($f->strand == 1, 'orientation -> strand');
  
sub test {
  ok($f->display_id      , 'display ID');
  ok($f->display_label   , 'display label');
  ok($f->start           , 'start');
  ok($f->end             , 'end');
  ok($f->strand == 1     , 'strand');
  ok($f->seq_region_start, 'seq region start');
  ok($f->seq_region_end  , 'seq region end');
  ok($f->type_label      , 'type label');
  ok($f->type_id         , 'type ID',);
  ok($f->type_category   , 'type category');
  ok($f->score           , 'score');

  ok(@{ $f->links }, 'has link');
  for my $l ( @{ $f->links() } ) {
    ok($l->{'href'}, 'link href');
    ok($l->{'txt'} , 'link text');
  }
  
  ok(@{ $f->notes }, 'has note');
  for my $n ( @{ $f->notes() } ) {
    ok($n, 'note content');
  }
 
  ok(@{ $f->targets }, 'has target'); 
  for my $t ( @{ $f->targets() } ) {
    ok($t->{'target_id'}   , 'target ID');
    ok($t->{'target_start'}, 'target start');
    ok($t->{'target_stop'} , 'target stop');
  }
  
  ok(@{ $f->groups }, 'has group');
  for my $g ( @{ $f->groups() } ) {
    ok($g->display_id   , 'group ID');
    ok($g->display_label, 'group label');
    ok($g->type_label   , 'group type');
    
    ok(@{ $g->links }, 'group has link');
    for my $l ( @{ $g->links() } ) {
      ok($l->{'href'}, 'group link href');
      ok($l->{'txt'} , 'group link text');
    }
    
    ok(@{ $g->notes }, 'group has note');
    for my $n ( @{ $g->notes() } ) {
      ok($n, 'group note content');
    }
    
    ok(@{ $g->targets }, 'group has target');
    for my $t ( @{ $g->targets() } ) {
      ok($t->{'target_id'}   , 'group target ID');
      ok($t->{'target_start'}, 'group target start');
      ok($t->{'target_stop'} , 'group target stop');
    }
  }
}