# omim morbid map parser
use DBI;
use strict;


my $dsn = "DBI:mysql:database=disease;host=ecs1c.sanger.ac.uk";
my $db = DBI->connect("$dsn",'root');

my $file='morbidmap.feb';
open(FH,$file) || die "cant open $file"; 


my $sth = $db->prepare("insert into last_update (disease) values (now())");    
$sth->execute();




my $entry_counter;
    
while (<FH>){
    $entry_counter++;
    
    my ($disease,$genes,$omim_id,$location)=split(/\|/,$_);
    $location =~s/^\s+//;
    $location =~s/\s+$//;
    $disease =~s/^\s+//;
    $disease =~s/\s+$//;
   
    

    my ($chromosome,$arm,$band_start,$sub_band_start,$band_end,$sub_band_end)=&prepare_locus_entry($location);
    my $start=$arm.$band_start;
    if (defined $sub_band_start){$start=$start.'.'.$sub_band_start;}
    my $end=$arm.$band_end;
    if (defined $sub_band_end){$end=$end.'.'.$sub_band_end;}
    
    

    my $marker_ins = $db->prepare("insert into disease (disease) values ('$disease')");
    $marker_ins->execute();
    
    
    my $sth4 = $db->prepare("select LAST_INSERT_ID()");
    $sth4->execute();
    
    my $arr = $sth4->fetchrow_arrayref();
    my $last_id = $arr->[0];
    
    
    my @array=split (/,/,$genes);
    
    #foreach my $gene(@array){
	
    my $gene=$array[0];
 
    $gene =~s/^\s+//;
    $gene =~s/\s+$//;
	
	my $marker_ins = $db->prepare
	    ("insert into gene (id,gene_symbol,omim_id,start_cyto,end_cyto,chromosome) 
              values ('$last_id','$gene','$omim_id','$start','$end','$chromosome')");
	$marker_ins->execute();
    #}				
    print "$omim_id\t$chromosome\t$arm\t$band_start\t$sub_band_start\t$band_end\t$sub_band_end\n";	
}

print "entry counter: $entry_counter\n";




sub prepare_locus_entry    
{
    my ($map_locus)=@_;
	    
    my $chromosome;
    my $arm;
    my $band_start;
    my $sub_band_start;
    my $band_end;
    my $sub_band_end;	    
    my $status=0;
    

    
    if ($map_locus =~/(.+)[-](.+)/)
    {
	my $from=$1;
	my $to =$2;
	$status=1;  
	
	
	if ($from =~ /(\d+|[X,Y])(\w+)$/)
	{
	    $chromosome =$1;
	    $arm =$2;		    		    
	}	
	

	if ($from =~ /(\d+|[X,Y])(\w)(\d+)[.](\d+)$/)
	{
	    $chromosome =$1;
	    $arm =$2;
	    $band_start=$3;
	    $sub_band_start=$4;   		    
	}				
	if ($from =~ /(\d+|[X,Y])(\w)(\d+)$/)
	{
	    $chromosome =$1;
	    $arm =$2;
	    $band_start=$3;		    		    
	}		

	

	if ($to =~ /(\d+|[X,Y])(\w)(\d+)[.](\d+)$/)
	{
	    $band_end=$3;
	    $sub_band_end=$4;   		    
	}
	if ($to =~ /(\d+|[X,Y])(\w)(\d+)$/){$band_end=$3;}		
	if ($to =~ /^(\d+)[.](\d+)/)
	{
	    $band_end=$1;
	    $sub_band_end=$2;   		    
	}
	if ($to =~ /^(\d+)$/){$band_end=$1;}
	if ($to =~ /(\d+|[X,Y])(cent)$/){$band_end=0;}		   
	if ($to =~ /^(\w+)$/){$band_end=$to;}
	if ($to =~ /^(\w)(\d+)$/){$band_end=$2;}
	if ($to eq 'qter'){$band_end='ter';}
	if ($to eq 'pter'){$band_end='ter';}
	if ($to =~ /^(\w)(\d+)[.](\d+)$/){$band_end=$2.'.'.$3;}
    }
    
    
    else 
    {		


	if ($map_locus =~ /^(\d+|[X,Y])(\w+)$/)
	{
	    $chromosome =$1;
	    $arm =$2;	
	    $status=1;	    		    
	}	

				
	if ($map_locus =~ /^(\d+|[X,Y])(\w)(\d+)[.](\d+)$/)
	{    
	    $chromosome =$1;
	    $arm =$2;
	    $band_start=$3;
	    $sub_band_start=$4;   
	    $status=1;
	    $band_end=$band_start;
	    $sub_band_end=$sub_band_start;
	}		
	if ($map_locus =~ /^(\d+|[X,Y])(\w)(\d+)$/)
	{	   
	    $chromosome =$1;
	    $arm =$2;
	    $band_start=$3;   
	    $band_end=$band_start;		   
	    $status=1;		    
	}
	

	if ($map_locus =~ /^Chr[.](\d+)$/)
	{
	    $chromosome =$1;		    		    
	    $status=1;
	}	


	
	# all the rest
	elsif ( $status==0)
	{
#	     print "map locus: $map_locus\n";		    
#	    print "weired NOT dONE\n";
	}
	
    }	
    
    #print "BAND END $band_end\n";
    
    my @locus_list=($chromosome,$arm,$band_start,$sub_band_start,$band_end,$sub_band_end);
    return @locus_list;
}	

 












