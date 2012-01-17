use strict;

my $dir="ncbi.nlm.nih.gov/pub/sage/info/";

opendir (DIR,$dir) || die "cant open $dir";


my $l_file;
my %libs;
my %key_words;

while (my $lib_file=readdir(DIR)){

    open (FH,$dir.$lib_file) || die "cant open $lib_file";


    if ($dir.$lib_file eq "../info/." || $dir.$lib_file eq "../info/."){next;}

    my @tissue;
    my @description;
    my $status;
    my $tissue_status;
    my $cgap_id;
    my $dbest_id;
    my %key_words_per_lib;

    while (<FH>)
    {
	if (/^CGAP/){
	    my @array=split;
	    $cgap_id=pop @array;
	}

	if (/dbEST/){
	   my @array=split;    
	   $dbest_id=pop @array; 	    
	} 

	if(/^Keyword/){
	    my ($key,$word)=split();
	    $key_words{$word}=1;
	     $key_words_per_lib{$word}=1;

	}
    
	if (/^Tissue_type/){
	    $tissue_status=1;	   	   
	}	
	

	if (/^Description/){
	    $status=1;
	    $tissue_status=0;
	}	

	
	if($tissue_status==1){
	    chomp;
	    my @array=split;
	    push @tissue,@array;	    
	}

	if (/^Tissue/){
	    $status=0;	
	}   
	
	if ($status==1){ 
	    $_=~s/Description: //;
   
	    chomp;
	    push @description,$_;
	}
    }


    shift @tissue;
    my $tissue=join (' ',@tissue);
   
    my $description=join (' ',@description);

   

    $libs{$lib_file}->{description}=$description;
    $libs{$lib_file}->{tissue}=$tissue;
    $libs{$lib_file}->{cgap_id}=$cgap_id;
    $libs{$lib_file}->{dbest_id}=$dbest_id;
    $libs{$lib_file}->{key_words}=\%key_words_per_lib;

}







my $file="tag_lib_freq";

open(FH,$file) || die "cant open $file";


my %trans;
my $lib_no;
my $trans_no;

print STDERR "scanning ... $file\n";

while (<FH>){
    chomp;
    my ($tag,$sage_id,$lib_name,$freq,$total)=split (/\t/);
        
    unless (defined $libs{$lib_name}->{lib_no}){
	$lib_no++;

	$libs{$lib_name}->{lib_no}=$lib_no;
	$libs{$lib_name}->{total}=$total;
    }
    
    unless (defined $trans{$tag}){
	$trans_no++;
	
	$trans{$tag}=$trans_no;
    }
}

close (FH);



system ("mkdir txt");


my $library_file=">txt/library.txt";
my $transcript_file=">txt/seqtag.txt";
my $frequency_file=">txt/frequency.txt";
my $keyword_file=">txt/key_word.txt";
my $keylibrary_file=">txt/lib_key.txt";


open (LB,$library_file) || die "cant open $library_file";
foreach my $key (sort {$libs{$a}->{lib_no} <=> $libs{$b}->{lib_no}} keys %libs){
    if (defined $libs{$key}->{lib_no}){
	print LB $libs{$key}->{lib_no},"\t","1","\t",$libs{$key}->{cgap_id},"\t",$libs{$key}->{dbest_id},
	"\t",$key,"\t",$libs{$key}->{tissue},"\t",$libs{$key}->{description},"\t",$libs{$key}->{total},"\n";
    }
}
close(LB);


print STDERR "written ... $library_file\n";


open (TR,$transcript_file) || die "cant open $transcript_file";
foreach my $key (sort {$trans{$a} <=> $trans{$b}} keys %trans){
    
    print TR $trans{$key},"\t","1","\t",$key,"\n";
    
}
close (TR);

print STDERR "written ... $transcript_file\n";


open(FH,$file) || die "cant open $file";
open (FR,$frequency_file) || die "cant open $frequency_file";
while (<FH>){
    chomp;
    my ($tag,$sage_id,$lib_name,$freq,$total)=split (/\t/);
    
    print FR $trans{$tag},"\t",$libs{$lib_name}->{lib_no},"\t",$freq,"\n";
    
}

close(FH);
close (FR);

print STDERR "written ... $frequency_file\n";



open (KEY_WORD,$keyword_file) || die "cant open $keyword_file";
my $counter;
foreach my $key (keys %key_words){
    $counter++;
    $key_words{$key}=$counter;
    print KEY_WORD $counter,"\t",$key,"\n";
    
}
close (KEY_WORD);


print STDERR "written ... $keyword_file\n";




open (KEY_LIBRARY,$keylibrary_file) || die "cant open $keyword_file";
my $counter;


foreach my $key (sort {$libs{$a}->{lib_no} <=> $libs{$b}->{lib_no}} keys %libs){
    if (defined $libs{$key}->{lib_no}){

	foreach my $keyword (keys %{$libs{$key}->{key_words}}){

	    print KEY_LIBRARY $libs{$key}->{lib_no},"\t",$key_words{$keyword},"\n";
	}


    }

}



close (KEY_LIBRARY);


print STDERR "written ... $keylibrary_file\n";

