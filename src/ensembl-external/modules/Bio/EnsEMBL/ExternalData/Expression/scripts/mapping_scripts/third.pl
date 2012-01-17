use strict;


my $tag_file="input_data/seqtag_id.dat";
my $tag_uni_file="input_data/SAGEmap_ug_tag-rel-Nla3-Hs";
my $body_map_file="input_data/HS2GS.txt";
my $map_file="input_data/final_joiner.dat";
my $txt_file=">input_data/seqtag_alias_before_sort.txt";


open (FH,$tag_file) || die "cant open $tag_file";

my %tags;
while (<FH>){
    /^seqtag/ && next;

    chomp;
    my ($id,$tag)=split;
    $tags{$tag}=$id;

}
close (FH);

print STDERR "finished tag file\n";

open (FH,$tag_uni_file) || die "cant open $tag_uni_file";

my %tags_uni;
while (<FH>){
    chomp;
my ($uni,$description,$tag)=split;
   $tags_uni{$tag}=$uni;

}

close (FH);

print STDERR "finished unifile\n";

open (FH,$body_map_file) || die "cant open $body_map_file";
my %body_map;

while (<FH>){

    my ($sth,$uni,$body_map,$sth)=split;

    $uni=~/(Hs\.)(\w+)/;
    $body_map{$2}=$body_map;
}
close (FH);


print STDERR "finished bodymapfile\n";

open (FH,$map_file) || die "cant open $map_file";

my %map;
while (<FH>){

    chomp;
    my ($enst,$ensg,$ensp,$uni,$tag)=split;

    push @{$map{$tag}->{enst}},$enst;
    push @{$map{$tag}->{ensg}},$ensg;
    push @{$map{$tag}->{ensp}},$ensp;
    push @{$map{$tag}->{uni}},$uni;


}

print STDERR "finished finaljoinerfile\n";


open(TXT,$txt_file) || die "cant open $txt_file";

foreach my $key (sort {$tags{$a}<=>$tags{$b}} keys %tags){

    print TXT $tags{$key},"\t","sage","\t",$key,"\n";
       
    foreach my $enst (@{$map{$key}->{enst}}){
	print TXT $tags{$key},"\t","enstrans","\t",$enst,"\n";
    }    
    
    foreach my $ensg (@{$map{$key}->{ensg}}){
	print TXT $tags{$key},"\t","ensgene","\t",$ensg,"\n";
    }
    
    foreach my $ensp (@{$map{$key}->{ensp}}){
	print TXT $tags{$key},"\t","enspep","\t",$ensp,"\n";
    }
    
    if (defined $map{$key}->{uni}->[0]){
	foreach my $uni (@{$map{$key}->{uni}}){
	    print TXT $tags{$key},"\t","unigene","\t",$uni,"\n";
	    
	    if (defined $body_map{$uni}){
		print TXT $tags{$key},"\t","bodymap","\t",$body_map{$uni},"\n";	
	    }	
	}    
    }
    
    elsif (! defined $map{$key}->{uni}->[0] && defined $tags_uni{$key}){
	print TXT $tags{$key},"\t","unigene","\t",$tags_uni{$key},"\n";
	
	if (defined $body_map{$tags_uni{$key}}){
	    print TXT $tags{$key},"\t","bodymap","\t",$body_map{$tags_uni{$key}},"\n";	    
	}	
    }    
}


print STDERR "printed output to $txt_file\n";

