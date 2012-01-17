use strict;

BEGIN {
    $| = 1;
    use Test;
    plan tests => 1;
}

use Bio::EnsEMBL::ExternalData::DAS::SourceParser;

my $parser = Bio::EnsEMBL::ExternalData::DAS::SourceParser->new(
                                                                -proxy => $ENV{http_proxy}
                                                               );


my @urls = (
  ['www.ensembl.org',  'http://www.ensembl.org/das', ''],
  ['www.ensembl.org/', 'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org',  'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/', 'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/das',  'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/das/', 'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/das/dsn',  'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/das/dsn/', 'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/das/sources',  'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/das/sources/', 'http://www.ensembl.org/das', ''],
  ['http://www.ensembl.org/das/foo',  'http://www.ensembl.org/das', 'foo'],
  ['http://www.ensembl.org/das/foo/', 'http://www.ensembl.org/das', 'foo'],
  ['http://www.ensembl.org/das/sources/foo',  'http://www.ensembl.org/das', 'foo'],
  ['http://www.ensembl.org/das/sources/foo/', 'http://www.ensembl.org/das', 'foo'],
  ['das.sanger.ac.uk', 'http://das.sanger.ac.uk/das', ''],
  ['www.ebi.ac.uk/das-srv/genomicdas/das', 'http://www.ebi.ac.uk/das-srv/genomicdas/das', ''],
  ['foo', 'http://foo/das', ''],
);

for (@urls) {
  my ($raw, $e_server, $e_dsn) = @{$_};
  my ($server, $dsn) = $parser->parse_das_string( $raw );
  ok( $server, $e_server );
  ok( $dsn, $e_dsn );
}

my $sources = $parser->fetch_Sources( -location => 'http://www.ensembl.org/das', -species => 'Homo_sapiens' );
if ( ok($sources && ref $sources && ref $sources eq 'ARRAY' && scalar @{ $sources }) ) {
  ok( $sources->[0]->label );
  ok( $sources->[0]->url );
  ok( $sources->[0]->dsn );
  ok( $sources->[0]->homepage );
  ok( $sources->[0]->maintainer );
  ok( scalar @{ $sources->[0]->coord_systems || [] } );
}
