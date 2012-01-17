#
# BioPerl module for Bio::EnsEMBL::ExternalData::Disease::DBHandler
#
# Written by Arek Kasprzyk <arek@ebi.ac.uk>
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::Disease::DBHandler 

=head1 SYNOPSIS


my $diseasedb = new Bio::EnsEMBL::ExternalData::Disease::DBHandler( 
                              -user => 'ensembl', 
                              -dbname => 'disease',
                              -host=>'sol28.ebi.ac.uk',
                              -port=>'3307',
                              -ensdb=>$ensembldb,



my @diseases=$diseasedb->diseases_on_chromosome(22);
my @diseases=$diseasedb->diseases_without_genes;
my @diseases=$diseasedb->all_diseases;
my $disease =$diseasedb->disease_by_name("DiGeorge syndrome (2)");
my @diseases=$diseasedb->diseases_like("corneal");


=head1 DESCRIPTION

This object represents a disease database consisting of disease phenotype descriptions, 
chromosomal locations and/or associated genes from OMIM morbid map and 
Mitelman Catalogoue of Chromosome Abnormalities. 
In additon, when database representations of ensembl and map databases are set, 
it will provide a 'translation' of OMIM and Mitelman genes to ensembl gene predictions 
and their localization in local and global coordinates.   


=head1 AUTHOR - Arek Kasprzyk

Email arek@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut



package Bio::EnsEMBL::ExternalData::Disease::DBHandler; 


use strict;
use DBI;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Root;
use Bio::EnsEMBL::ExternalData::Disease::Disease;
use Bio::EnsEMBL::ExternalData::Disease::DiseaseLocation;
use vars qw(@ISA);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
@ISA = qw(Bio::EnsEMBL::Root);



sub new 
{
    my($class,@args) = @_;
    my $self = bless {}, $class;
    
    my ($db,$host,$port,$driver,$user,$password,$debug,$ensdb) = 
      rearrange([qw(DBNAME
                HOST
                PORT
                DRIVER
                USER
                PASS
                DEBUG
                ENSDB
                )],@args);
    

    $driver ||= 'mysql';
    $host   ||= 'localhost';
    $port   ||= 3306;
    $db     ||= 'disease';
    $user   ||= 'ensembl';   
   
    $ensdb && $self->_ensdb($ensdb); 
    
    my $dsn = "DBI:$driver:database=$db;host=$host;port=$port";
    if( $debug && $debug > 10 ) {
    $self->_db_handle("dummy dbh handle in debug mode $debug");
    } else {
    my $dbh = DBI->connect("$dsn","$user",$password,{RaiseError => 1});
    $dbh || $self->throw("Could not connect to database $db user $user using [$dsn] as a locator");
    $self->_db_handle($dbh);
    }
    
    
    return $self; 
}




=head2 add_db_adaptor

  Arg [1]   : Bio::EnsEMBL::DBSQL::DBAdaptor object
  Function  : Registers core database with this adaptor
  Returntype: Bio::EnsEMBL::DBSQL::DBAdaptor object
  Exceptions: none
  Caller    : EnsEMBL::DB::Core
  Example   : 

=cut

sub add_db_adaptor {
  my $self = shift;
  my $ensdb = shift || $self->throw("Need an ensembl DB adaptor");
  return $self->_ensdb($ensdb); 
}






=head2 disease_by_name

 Title   : disease_by_name
 Usage   : my $disease=$diseasedb->disease_by_name("DiGeorge syndrome (2)");
 Function: gets disease by name
 Example :
 Returns : Bio::EnsEMBL::ExternalData::Disease::Disease object
 Args    :


=cut



                     
sub disease_by_name
{                          
    my ($self,$disease_name)=@_;

 my $query_string= "select d.disease,g.id,g.gene_symbol,g.omim_id,g.start_cyto,g.end_cyto,
                    g.chromosome from disease as d,gene as g where d.id = g.id 
                    and d.disease='$disease_name'";

    return $self->_get_disease_objects($query_string);

}





=head2 disease by omim id

 Title   : disease_by_omim_id
 Usage   : my $disease=$diseasedb->disease_by_omim_id("201810");
 Function: gets disease by omim id 
 Example :
 Returns : Bio::EnsEMBL::ExternalData::Disease::Disease object
 Args    :


=cut




sub disease_by_omim_id
{
    my ($self,$omim_id)=@_;

 my $query_string= "select d.disease,g.id,g.gene_symbol,g.omim_id,g.start_cyto,g.end_cyto,
                    g.chromosome from disease as d,gene as g where d.id = g.id
                    and g.omim_id='$omim_id'";

    return $self->_get_disease_objects($query_string);

}







=head2 disease by ensembl gene

 Title   : disease_by_ensembl_gene
 Usage   : my @diseases=$diseasedb->disease_by_ensembl_gene($gene);
 Function: gets disease (if any) for an EnsEMBL Gene object
 Returns : A list of Bio::EnsEMBL::ExternalData::Disease::Disease object or 0 if none
 Args    : Bio::EnsEMBL::Gene object


=cut
                     
sub disease_name_by_ensembl_gene
{                          
  my ($self,$gene) = @_;
  $self->throw("$gene is not a Bio::EnsEMBL::Gene object!") unless 
    $gene->isa('Bio::EnsEMBL::Gene');
	
  my $DBlinks = ( $gene->get_all_DBLinks || [] );
  my @genes = ( map  { $_->display_id, @{$_->get_all_synonyms || [] } } 
		grep { $_->database eq 'HUGO' } @$DBlinks );
  return 0 unless @genes;   

  my $query_string = "select distinct d.disease, g.omim_id
          from disease as d,gene as g
          where d.id = g.id and g.gene_symbol in (".
	    join(',' , map {$self->_db_handle->quote($_)} @genes) .
	      ") order by d.disease";
  return $self->_get_disease_objects($query_string);

}






=head2 all_diseases

 Title   : all_diseases
 Usage   : my @diseases=$diseasedb->all_diseases[(30,10)];
 Function: gets all diseases from the database, with optional offset,limit
 Example :
 Returns : an array of Bio::EnsEMBL::ExternalData::Disease::Disease objects
 Args    :


=cut

sub all_diseases 
{
    my ($self,$offset,$count)=@_;
    
    my $query_string='';

    if (defined $offset){
        $offset='limit '.$offset;
        if($count){$count=','.$count;}
        my $get_disease_ids_sql="SELECT distinct d.id 
                        FROM disease AS d,gene AS g 
                        WHERE d.id = g.id $offset $count;";
        my $sth=$self->_db_handle->prepare($get_disease_ids_sql);
        $sth->execute;
    
        my @ids;
        while ( my $rowhash = $sth->fetchrow_hashref){
            push @ids, $rowhash->{'id'};
        }
        if (scalar @ids){
        my $id_string=join(',',@ids);

        $query_string= "SELECT  d.disease,
                                    g.id,
                                    g.gene_symbol,
                                    g.omim_id,
                                    g.start_cyto,
                                    g.end_cyto, 
                                    g.chromosome 
                            FROM disease AS d,gene AS g 
                            WHERE g.id=d.id 
                            AND d.id IN ($id_string)";

        }
        else {
            # no matches for this query, so:
            return ();
        }
    }
    else {
        $query_string='SELECT   d.disease,
                                    g.id,
                                    g.gene_symbol,
                                    g.omim_id,
                                    g.start_cyto,
                                    g.end_cyto, 
                                    g.chromosome 
                        FROM disease AS d,gene AS g 
                        WHERE d.id = g.id';
    }
    
    return $self->_get_disease_objects($query_string);

} 





=head2 all_disease_names

 Title   : all_disease_names
 Usage   : my @diseases=$diseasedb->all_disease_names(90,2);
 Function: gets all disease names from the database limites by offset and count
 Example :
 Returns : an array of disease names (strings)
 Args    :


=cut

sub all_disease_names 
{
    my ($self,$offset,$count)=@_;

    if ($offset||$offset == 0){$offset='limit '.$offset;}
    if($count){$count=','.$count;}
  

    my $query_string="select  disease from disease $offset $count;";

    $self->_get_disease_names($query_string);

} 
                         




                       

=head2 all_disease_count

 Title   : all_disease_count
 Usage   : my $count=$diseasedb->all_disease_count;
 Function: number of diseases
 Example :
 Returns : a number of diseases
 Args    :


=cut

sub all_disease_count
{
    my ($self)=@_;

    my $query_string="SELECT disease FROM disease;";

    $self->_get_count($query_string);

} 
                         


                         

=head2 diseases_on_chromosome

 Title   : diseases_on_chromosome
 Usage   : my @diseases=$diseasedb->diseases_on_chromosome(22,90,30);
 Function: gets all diseases for a given chromosome limited by offset and count
 Example :
 Returns : an array of Bio::EnsEMBL::ExternalData::Disease::Disease objects
 Args    :


=cut

sub diseases_on_chromosome 
{                          
    my ($self,$chromosome_no,$offset,$count)=@_;
    my $query_string='';
    
    $chromosome_no || $self->throw("I need a chromosome");
    
    # If we've got limits, then do a limited query, otherwise, do a full query
    # There was a bug, $offset||$offset == 0, fixed.
    if (defined $offset){
        $offset='limit '.$offset;
        if($count){$count=','.$count;}
    
        my $get_disease_ids_sql="SELECT distinct d.id 
                                FROM disease AS d,gene AS g 
                                WHERE d.id = g.id 
                                AND g.chromosome='$chromosome_no' 
                                $offset $count;";


        my $sth=$self->_db_handle->prepare($get_disease_ids_sql);
        $sth->execute;
    
        my @ids;
        while ( my $rowhash = $sth->fetchrow_hashref){
            push @ids, $rowhash->{'id'};
        }

        if (scalar @ids){
            my $id_string=join(',',@ids);

            $query_string= "SELECT  d.disease,
                                        g.id,
                                        g.gene_symbol,
                                        g.omim_id,
                                        g.start_cyto,
                                        g.end_cyto,
                                        g.chromosome 
                                FROM disease AS d,gene AS g 
                                WHERE g.id=d.id 
                                AND d.id IN ($id_string)";
        }
        else {
            return ();
        }
    }
    else {
        $query_string= "SELECT  d.disease,
                                    g.id,
                                    g.gene_symbol,
                                    g.omim_id,
                                    g.start_cyto,
                                    g.end_cyto,
                                    g.chromosome 
                            FROM disease AS d,gene AS g 
                            WHERE g.id=d.id 
                            AND g.chromosome='$chromosome_no'";
    }
    
    return $self->_get_disease_objects($query_string);
       
}




=head2 disease_names_on_chromosome

 Title   : diseases_names_on_chromosome
 Usage   : my @diseases=$diseasedb->disease_name_on_chromosome(90,2);
 Function: gets all disease names per chromosome limited by offset and count
 Example :
 Returns : an array of disease names (strings)
 Args    :


=cut

sub disease_names_on_chromosome 
{
    my ($self,$chromosome_no,$offset,$count)=@_;

    $chromosome_no || $self->throw("I need a chromosome");
    if ($offset||$offset == 0){$offset='limit '.$offset;}
    if($count){$count=','.$count;}    

    my $query_string="SELECT distinct g.id, d.disease 
                        FROM disease AS d,gene AS g 
                        WHERE d.id = g.id 
                        AND g.chromosome='$chromosome_no' $offset $count;";
    
    $self->_get_disease_names($query_string);

} 
                         





=head2 diseases_on_chromosome_count

 Title   : disease on chromosome count
 Usage   : my $count=$diseasedb->diseases_on_chromosome_count(3);
 Function: number of diseases
 Example :
 Returns : a number of diseases
 Args    :


=cut

sub diseases_on_chromosome_count
{
    my ($self,$chromosome)=@_;

    $chromosome || $self->throw("I need a chromosome");

    my $query_string= "SELECT distinct g.id, d.disease  
                        FROM disease AS d,gene AS g 
                        WHERE d.id = g.id 
                        AND g.chromosome='$chromosome'";

    $self->_get_count($query_string);

} 
     



=head2 diseases_with_genes

 Title   : diseases_with_genes
 Usage   : my @diseases=$diseasedb->diseases_with_genes;
 Function: gets all diseases associated with genes
 Example :
 Returns : an array of Bio::EnsEMBL::ExternalData::Disease::Disease objects
 Args    :


=cut

sub diseases_with_genes 
    
{
    my ($self)=@_;

    my $query_string= "select d.disease,g.id,g.gene_symbol,g.omim_id,g.start_cyto,g.end_cyto, 
                       g.chromosome from disease as d,gene as g where d.id = g.id 
                       and g.gene_symbol IS NOT NULL";

    return $self->_get_disease_objects($query_string);


} 





=head2 disease_names_with_genes

 Title   : disease_names_with_genes
 Usage   : my @diseases=$diseasedb->disease_names_with_genes(90,3);
 Function: gets all diseases associated with genes limited by offset and count
 Example :
 Returns : an array of disease names
 Args    :


=cut

sub disease_names_with_genes 
    
{
   
  my ($self,$offset,$count)=@_;

  if ($offset||$offset == 0){$offset='limit '.$offset;}
  if($count){$count=','.$count;}    
    
  my $query_string= "select  d.disease from disease as d,gene as g where d.id = g.id 
                       and g.gene_symbol IS NOT NULL $offset $count";

  $self->_get_disease_names($query_string);


} 




=head2 diseases_with_genes_count

 Title   : disease with genes count
 Usage   : my $count=$diseasedb->diseases_with_genes_count(3);
 Function: number of diseases with genes
 Example :
 Returns : a number of diseases with genes
 Args    :


=cut

sub diseases_with_genes_count
{
    my ($self)=@_;

    my $query_string= "select  disease from disease as d,gene as g where d.id = g.id 
                       and g.gene_symbol IS NOT NULL;";

    $self->_get_count($query_string);

} 
     



=head2 diseases_without_genes

 Title   : diseases_without_genes
 Usage   : my @diseases=$diseasedb->diseases_without_genes;
 Function: gets all diseases which have no gene info in the database
 Example :
 Returns : an array of Bio::EnsEMBL::ExternalData::Disease::Disease objects
 Args    :


=cut

sub diseases_without_genes 
{
    my ($self)=@_;

    my $query_string= "select d.disease,g.id,g.gene_symbol,g.omim_id,g.start_cyto,g.end_cyto, 
                       g.chromosome from disease as d,gene as g where d.id = g.id 
                       and g.gene_symbol IS NULL";


    return $self->_get_disease_objects($query_string);


} 




=head2 disease_names_without_genes

 Title   : disease_names_without_genes
 Usage   : my @diseases=$diseasedb->disease_names_without_genes(90,3);
 Function: gets all diseases associated with genes limited by offset and count
 Example :
 Returns : an array of disease names
 Args    :


=cut

sub disease_names_without_genes 
    
{
   
  my ($self,$offset,$count)=@_;

  if ($offset||$offset == 0){$offset='limit '.$offset;}
  if($count){$count=','.$count;}    
  
  my $query_string= "select d.disease from disease as d,gene as g where d.id = g.id 
                       and g.gene_symbol IS NULL  $offset,$count";

  $self->_get_disease_names($query_string);

} 





=head2 diseases_without_genes_count

 Title   : disease without genes count
 Usage   : my $count=$diseasedb->diseases_without_genes_count(3);
 Function: number of diseases without genes
 Example :
 Returns : a number of diseases without genes
 Args    :


=cut

sub diseases_without_genes_count
{
    my ($self)=@_;

    my $query_string= "select  disease from disease as d,gene as g where d.id = g.id 
                       and g.gene_symbol IS NULL;";

    $self->_get_count($query_string);

} 
  



=head2 diseases_like

 Title   : diseases_like
 Usage   : my @diseases=$diseasedb->diseases_like("leukemia");
 Function: gets diseases with a name containing given string
 Example :
 Returns : an array of Bio::EnsEMBL::ExternalData::Disease::Disease objects
 Args    :


=cut

sub diseases_like 
{
    my ($self,$disease)=@_;

    $disease || $self->throw("I need disease name");
    
    my $query_string="select d.disease,g.id,g.gene_symbol,g.omim_id,g.start_cyto,g.end_cyto, 
                      g.chromosome from disease as d,gene as g where d.id = g.id and d.disease like '%$disease%'";

    return $self->_get_disease_objects($query_string);

} 
                         



=head2 disease_names_like

 Title   : disease_names_like
 Usage   : my @diseases=$diseasedb->disease_names_like("leukemia",3,2);
 Function: gets diseases names with a name containing given string
 Example :
 Returns : an array of disease names
 Args    :


=cut

sub disease_names_like 
{
    my ($self,$disease,$offset,$count)=@_;

    $disease || $self->throw("I need disease name");    

    if ($offset||$offset == 0){$offset='limit '.$offset;}
    if($count){$count=','.$count;}    



    my $query_string="select  d.disease from disease as d,gene as g 
                      where d.id = g.id and d.disease like '%$disease%' $offset $count";

    return $self->_get_disease_names($query_string);

} 
   





=head2 disease_name_like_count

 Title   : disease name like count
 Usage   : my $count=$diseasedb->disease_names_like_count(3);
 Function: number of diseases matching given string
 Example :
 Returns : a number of diseases matching given string 
 Args    :


=cut

sub disease_names_like_count
{
    my ($self,$disease)=@_;

    $disease || $self->throw("I need disease name");

    my $query_string= "select  disease from disease as d,gene as g 
                      where d.id = g.id and d.disease like '%$disease%'";

    $self->_get_count($query_string);

} 
  





sub _get_disease_objects
{

my ($self,$query_string)=@_;

my $sth=$self->_db_handle->prepare($query_string);
$sth->execute;


my $id;
my @diseases;
my $disease;

while ( my $rowhash = $sth->fetchrow_hashref) 
{
    if (!defined($id) or $id != $rowhash->{'id'})
    {   
    $disease=new Bio::EnsEMBL::ExternalData::Disease::Disease;
    $disease->name($rowhash->{'disease'});
    push @diseases,$disease;
    }

    my $location=new Bio::EnsEMBL::ExternalData::Disease::DiseaseLocation(
                                -db_id=>$rowhash->{'omim_id'},
                                -cyto_start=>$rowhash->{'start_cyto'},
                                -cyto_end=>$rowhash->{'end_cyto'},
                                -external_gene=>$rowhash->{'gene_symbol'},
                                -chromosome=>$rowhash->{'chromosome'});
  
    if (defined $rowhash->{'gene_symbol'}){$location->has_gene(1);}
    $id=$rowhash->{'id'};
    $disease->add_Location($location);   
}


if (defined $self->_ensdb){@diseases=$self->_link2ensembl(@diseases);}


return @diseases;


}




sub _get_disease_names
{
    my ($self,$query_string)=@_;

    my $sth=$self->_db_handle->prepare($query_string);
    $sth->execute;


    my @diseases;

    while ( my $rowhash = $sth->fetchrow_hashref) 
    {
    push @diseases,$rowhash->{'disease'};   
    }

    return @diseases;


}



sub _get_count
{
    my ($self,$query_string)=@_;
    
    my $sth=$self->_db_handle->prepare($query_string);
    $sth->execute;

    my @diseases;
    
    while ( my $rowhash = $sth->fetchrow_hashref) 
    {
    push @diseases,$rowhash->{'disease'};   
    } 

    scalar @diseases;


}



sub _link2ensembl {
  my ($self,@diseases)=@_;
  foreach my $dis (@diseases){ 
    foreach my $location($dis->each_Location){ 
      eval {
#        my $ensembl_gene = $self->_ensdb->get_GeneAdaptor->fetch_by_maximum_DBLink($location->external_gene);
        my $ensembl_gene = $self->_ensdb->get_GeneAdaptor->fetch_all_by_external_name($location->external_gene);
        $location->ensembl_gene($ensembl_gene);
      };
      if ($@){print STDERR "problems with ensembl genes\n$@\n";}
    }
  }
  return @diseases;
}



sub _db_handle 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'_db_handle'} = $value;}
  
  return $self->{'_db_handle'};
}


sub _prepare
{
    my ($self,$string) = @_;
    
    if( ! $string ) {$self->throw("Attempting to prepare an empty SQL query!");}
    
    my( $sth );
    eval {$sth = $self->_db_handle->prepare($string);};
    $self->throw("Error preparing $string\n$@") if $@;
    return $sth;
    
}


sub _ensdb 
{
  my ($self,$value) = @_;
  if( defined $value) {$self->{'_ensdb'} = $value;}
  
  return $self->{'_ensdb'};
}












