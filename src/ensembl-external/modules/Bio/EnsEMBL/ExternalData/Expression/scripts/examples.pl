use strict;
use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor;
use Bio::EnsEMBL::ExternalData::Expression::LibraryAdaptor;
my $obj= Bio::EnsEMBL::DBSQL::Obj->new(-dbname=>'expression',-user=>'ensadmin',-host=>'ecs1c');

my $dbname='expression';
my $lib_ad=Bio::EnsEMBL::ExternalData::Expression::LibraryAdaptor->new($obj);
my $tag_ad= Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($obj);





#my @tags=$tag_ad->list_all_ids;
#foreach my $name (@tags){print "$name\n";}


#my @libs=$lib_ad->fetch_all;
#my @libs=$lib_ad->fetch_by_SeqTag_Name("AAAAAAAAAT");

my $ensgene="AAAAAAAAAA";
my @libs=$lib_ad->fetch_by_SeqTag_Name($ensgene); 
#my @libs=$lib_ad->fetch_by_SeqTag_Synonym_below_relative_frequency("ENSG00000080561",1000);
#my @tgs=("AAAAAAAAAA","AAAAAAAAAC");
#my @libs=$lib_ad->fetch_by_SeqTagList(@tgs);

#my @tgs=("ENSG00000080561","ENSG00000087370");
#my @libs=$lib_ad->fetch_by_SeqTag_SynonymList(@tgs);

my @tgs=$tag_ad->fetch_by_Name_with_allAliases($ensgene);

foreach my $t(@tgs){
   

    foreach my $link ($t->each_DBLink){
    
 print $link->primary_id," ",$link->database,"\n";

    }


}


foreach my $lib (@libs){
    print $lib->name,"\n";
    my @tgs=$lib->fetch_SeqTag_by_Name($ensgene);
    foreach my $tg(@tgs){
	
	foreach my $link ($tg->each_DBLink){ if ($tg->name ne "AAAAAAAAAA"){
 #print $lib->name,"\n";
	    print $link->primary_id,"\t",$tg->name,"\t",$tg->relative_frequency,"\t",$tg->frequency,"\t",$lib->total_seqtags,"\n";
	}
	}
}    

    

#    foreach my $tag($lib->fetch_all_SeqTags_above_relative_frequency(5000)){
#	foreach my $link ($tag->each_DBLink){
#	    if ($link->database eq 'enstrans'){
#		print $tag->name," ",$link->primary_id," ",$tag->relative_frequency,"\n";
		
#	    }    
#	}
#    }

}

#exit;

#my $lib=$lib_ad->fetch_by_dbID(1);
my $libname="SAGE_Duke_H247_Hypoxia";
my $lib=$lib_ad->fetch_by_Name($libname);


print "\n\n\n";
print $lib->name,"\n";
print "description:\n";
print $lib->description,"\n";

exit;



 foreach my $tag($lib->fetch_all_SeqTags_above_relative_frequency(1000)){
#     print $tag->name," ",$tag->relative_frequency,"\n";

foreach my $link ($tag->each_DBLink){
	    if ($link->database eq 'bodymap'){
		print $tag->name," ",$link->primary_id," ",$tag->relative_frequency,"\n";
		
	    }    
	}


 }






#my @tags=$tag_ad->fetch_by_Library_Name("SAGE_Duke_1273");

#my @ids=(1,2,3,4,5,6,7,8,9);
#my @tags=$tag_ad->fetch_by_LibraryList_dbIDs(@ids);
#my @tags=$tag_ad->fetch_by_Library_dbID(2);

#my @tags=$tag_ad->fetch_by_Library_dbID(1);

#my @tags=$tag_ad->fetch_all;

#my @tags=$tag_ad->fetch_by_dbID(10);
#my @tags=$tag_ad->fetch_by_Name("AAAAAAAAAA");

#foreach my $tag(@tags){
#    print $tag->id,$tag->name," ",$tag->relative_frequency,"\n";
    
    #foreach my $link ($tag->each_DBLink){
   	#if ($link->database eq 'ensgene'){	    
   	#    print $link->primary_id," ",$tag->relative_frequency,"\n";
   	#}	
    #}
#}




#my @tags=$tag_ad->list_all_ids;
#foreach my $name (@tags){print "$name\n";}




















