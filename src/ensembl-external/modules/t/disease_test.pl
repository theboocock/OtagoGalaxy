use strict;
use Bio::EnsEMBL::Map::DBSQL::Obj;
use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::ExternalData::Disease::DBHandler;




my $user='ensro';
my $host='ecs1c';
my $mapdb = new Bio::EnsEMBL::Map::DBSQL::Obj( -user => $user, 
					    -dbname => 'maps075', 
					    -host=>$host,
					    -ensdb=>'ens075');



my $ensembldb = new Bio::EnsEMBL::DBSQL::Obj( -user => $user, 
					    -dbname => 'ens075',
					    -host=>$host);


my $diseasedb = new Bio::EnsEMBL::ExternalData::Disease::DBHandler( -user => $user, 
						      -dbname => 'disease',
						      -host=>$host,
						      -ensdb=>$ensembldb,
						      -mapdb=>$mapdb);





#my @diseases=$diseasedb->diseases_on_chromosome(22,0,2000);
#my @diseases=$diseasedb->diseases_without_genes;

my @diseases;
eval {	
@diseases=$diseasedb->all_diseases(0,2000);
};

if ($@){print STDERR "problems with ensembl gene\n$@\n";}


#my @diseases_names=$diseasedb->all_disease_names_limit();
#my @diseases_names=$diseasedb->disease_names_on_chromosome_limit(1,90,3);

#my @diseases_names=$diseasedb->disease_names_with_genes(90,3);
#my @diseases_names=$diseasedb->disease_names_without_genes(4,3);
#my @diseases=$diseasedb->diseases_like("leukemia");
#my @diseases_names=$diseasedb->disease_names_like("diabetes",4,5);
#my @diseases=$diseasedb->disease_by_name("DiGeorge syndrome (2)");
#my @diseases=$diseasedb->disease_by_name("Albinism, rufous, 278400 (3)");




#my $gene_db=Bio::EnsEMBL::DBSQL::Gene_Obj->new($ensembldb);
#my $gene= $gene_db->get_Gene_by_Transcript_id('F15T00000049048');
#my $gene= $gene_db->get('F15G00000028732');
#my @genes = $ensembldb->get_object_by_wildcard('gene','F15G00000028732%');
#my $gene=$genes[0];

#if ($diseasedb->disease_name_by_ensembl_gene($gene)) {
    
#    my @diseases_names=$diseasedb->disease_name_by_ensembl_gene($gene);
    
    
#    foreach my $disease_name (@diseases_names)
#    {
#	print STDERR $disease_name,"\n";
#    }
#}
#else {
#    print STDERR "No diseases for this gene\n";
#}
#print "count ",$diseasedb->all_disease_count,"\n";


#print STDERR "size ",$#diseases,"\n";
#exit;


foreach my $dis (@diseases)
{
    #print $dis->name,"\n";


    foreach my $location($dis->each_Location){
	
		#print "has gene ",$location->external_gene," on chromosome ",
		#$location->chromosome," (",$location->cyto_start,"-",$location->cyto_end,")","\n";

	my $ensembl_gene;
#eval {	
	if (defined $location->ensembl_gene){
	    $ensembl_gene=$location->ensembl_gene->id;

	    #print $dis->name," ",$location->external_gene," = ",$location->ensembl_gene->id,"\n";
	}
	#else {print "no ensembl predictions for ", $location->external_gene,"\n";}
#    };
#	if ($@){print STDERR "problems with ensembl gene\n$@\n";}

	else {$ensembl_gene="NO_PREDICTION";}
	print  $location->chromosome,"\t",$dis->name,"\t",$location->external_gene,"\t",$ensembl_gene,"\n";


    }
}















