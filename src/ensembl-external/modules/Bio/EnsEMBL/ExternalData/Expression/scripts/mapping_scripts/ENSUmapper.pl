#
#
# ensembl_130 version
#

use strict;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $db=Bio::EnsEMBL::DBSQL::DBAdaptor->new(-dbname=>"homo_sapiens_core_130",-user=>"ensro",-host=>"ecs1d"); 
$db->assembly_type('NCBI_26');

my $stadaptor = $db->get_SliceAdaptor();
my $file="/nfs/acari/lh1/work/sage/for_release/chr.dat";
open (FH,$file) || die "cant open $file";
while (<FH>){
        chomp;
    /^\#/ && next;
    print STDERR "chromosome ",$_,"\n";
    my $contig=$stadaptor->fetch_by_chr_name($_);
    print STDERR "fetched vc\n";
    my @transcripts=sort {$a->start <=> $b->start}$contig->get_all_VirtualTranscripts_startend();
    print STDERR "sorted transcripts ",$#transcripts,"\n";

    my @unigenes=sort {$a->start <=> $b->start}$contig->get_all_unigene_features();
    print STDERR "sorted unigenes ", $#unigenes,"\n";

    my $transcript_counter;
    my $index_pos=0;
    my $i;
    TRANSCRIPT:foreach my $transcript (@transcripts)
      {
      my $hit = 0;
      my $top_score = 0;
      my $top_id; 
      
      $transcript_counter++;

      print STDERR $_,"\t",$transcript->gene->dbID,"\t",$transcript_counter,"\t",$#transcripts,"\n";  # where are we now? report to SDTERR

my $u = 0;      
        UNIGENE:for($i = $index_pos; $i <= $#unigenes; $i++)
        {
	$u++;
        my $unigene   = $unigenes[$i];
        my $id        = $unigene->id;
	my $score     = $unigene->score; 	
        if (($unigene->start >= $transcript->start && $unigene->start <= $transcript->end) || ($unigene->end >= $transcript->start && $unigene->end <= $transcript->end))
	        {
                if ($score > $top_score)   
		   {
         	   $top_score = $score;
                   $top_id    = $id;
		   $hit       = 1;
      		   }
	        }
        if ($unigene->start > $transcript->end)
	   {
	   $index_pos = $i - 1;     
	   if ($hit == 1)
       	        {
                $top_id =~ s/Hs\.//;
		print $transcript->gene->dbID, "\t", $top_id, "\t", $top_score, "\n"; 
                print STDERR "I have looked through ", $u, "unigenes for you", "\n"; 
                }
           next TRANSCRIPT;           
	   }
        }
      }
}
print STDERR "I have finished!\n";








