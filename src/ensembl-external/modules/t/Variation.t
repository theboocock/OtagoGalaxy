# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: Variation.t,v 1.9 2001-04-10 15:30:45 heikki Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

#-----------------------------------------------------------------------
## perl test harness expects the following output syntax only!
## 1..3
## ok 1  [not ok 1 (if test fails)]
## 2..3
## ok 2  [not ok 2 (if test fails)]
## 3..3
## ok 3  [not ok 3 (if test fails)]
##
## etc. etc. etc. (continue on for each tested function in the .t file)
#-----------------------------------------------------------------------

use Test;
use strict;

BEGIN { plan tests => 25}

use Bio::EnsEMBL::ExternalData::Variation;
use Bio::Annotation::DBLink;
ok 1;

my ($obj, $link1);
ok $obj = Bio::EnsEMBL::ExternalData::Variation -> new;
ok ($obj->start(3) and $obj->start == 3 );
ok ($obj->end(3) and $obj->end == 3 );
ok ($obj->strand(1) and $obj->strand == 1 );
ok ($obj->original_strand(1) and $obj->strand == 1 );
ok $obj->primary_tag, 'Variation' ;
ok ($obj->source_tag('source') and $obj->source_tag eq 'source' );
ok ($obj->frame(2) and $obj->frame ==2 );
ok ($obj->score(2) and $obj->score ==2 );
ok ($obj->status('proven') and $obj->status eq 'proven' );
ok ($obj->alleles('a|t') and $obj->alleles eq 'a|t' );
ok ($obj->upStreamSeq('tgctacgtacgatcgatcga') and 
    $obj->upStreamSeq eq 'tgctacgtacgatcgatcga');
ok ($obj->dnStreamSeq('tgctacgtacgatcgatcga') and 
    $obj->dnStreamSeq eq 'tgctacgtacgatcgatcga' );

ok $link1 = new Bio::Annotation::DBLink;
ok $link1->database('TSC-CSHL');
ok $link1->primary_id('TSC0000030');
ok $obj->add_DBLink($link1);
foreach my $link ( $obj->each_DBLink ) {
    ok $link->database;
    ok $link->primary_id;
}
ok $obj->id, 'TSC0000030';

ok ($obj->seqname('seqname') and $obj->seqname eq 'seqname' );
ok ($obj->position_problem('position_problem') and 
    $obj->position_problem eq 'position_problem' );

my @as = $obj->to_FTHelper;
ok scalar @as, 2;
ok $as[1]->isa('Bio::SeqIO::FTHelper');
