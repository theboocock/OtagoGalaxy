#
# EnsEMBL module for Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor
#
# Cared for by EnsEMBL (www.ensembl.org)
#
# Copyright GRL and EBI
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor

=head1 SYNOPSIS

    my $dbname='expression';
    my $tag_ad= Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($obj);
    $tag_ad->dbname($dbname);
    my $tag=$sta->fetch_by_Name("AAAAAAAAAA");


=head1 DESCRIPTION

Represents information on one Clone

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut



package Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor;
use Bio::EnsEMBL::ExternalData::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Expression::SeqTag;
use Bio::Annotation::DBLink;
use vars qw(@ISA);
use strict;

@ISA = qw(Bio::EnsEMBL::ExternalData::BaseAdaptor);


=head2 list_all_names

 Title   : list_all_names
 Usage   : $obj->list_all_names($newval)
 Function: 
 Example : 
 Returns : array of seqtag names
 Args    :


=cut


sub list_all_names {
    my ($self)=shift;

   
    my $statement="select name from seqtag";

    return $self->_list($statement);   

}



=head2 list_all_ids

 Title   : list_all_ids
 Usage   : $obj->list_all_ids($newval)
 Function: 
 Example : 
 Returns : array of seqtag db ids
 Args    :


=cut



sub list_all_ids {
    my ($self)=shift;

   
    my $statement="select seqtag_id from seqtag";

    return $self->_list($statement);   

}



=head2 list_by_alias

 Title   : list_by_alias
 Usage   : $obj->list_by_alias($alias)
 Function: 
 Example : 
 Returns : array of seqtag db ids
 Args    :


=cut



sub list_by_alias {
    my ($self,$alias)=@_;

   
    my $statement="select s.name from seqtag s,seqtag_alias sa 
                   where s.seqtag_id=sa.seqtag_id and sa.external_name='$alias'";

    return $self->_list($statement);   

}










=head2 fetch_all

 Title   : fetch_all
 Usage   : $obj->fetch_all
 Function: 
 Example : 
 Returns : array of seqtag objects
 Args    :


=cut





sub fetch_all {
    my ($self)=shift;

   
    my $multiplier=$self->multiplier;    

    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency,
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa 
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id";

    return $self->_fetch($statement);  


}



=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   : $obj->fetch_by_dbID
 Function: 
 Example : 
 Returns :seqtag object
 Args    :db id


=cut




sub fetch_by_dbID {

    my ($self,$id)=@_;
 

    $self->throw("need a db id") unless  $id;

    
    my $multiplier=$self->multiplier; 

    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency,
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa, 
                          library l 
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id
                   and    l.library_id=f.library_id and s.seqtag_id=$id";

    my @tags=$self->_fetch($statement);  
    if ($#tags>=0){
	return shift @tags;
    }else {return;}
    
}




=head2 fetch_by_Synonym

 Title   : fetch_by_Synonym
 Usage   : $obj->fetch_by_Synonym
 Function: 
 Example : 
 Returns :array of seqtag objects
 Args    :seqtag name or alias


=cut





sub fetch_by_Synonym {

    my ($self,$lib_id,$synonym)=@_;
 
    $self->throw("need a library id") unless  $lib_id;
    $self->throw("need a tag synonym") unless  $synonym;

    
    my $multiplier=$self->multiplier; 

    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency,
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa,
                          library l 
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id  
                   and    l.library_id=f.library_id and l.library_id=$lib_id and sa.external_name='$synonym'";


    return $self->_fetch($statement);  
    
    
}


=head2 fetch_by_Name

 Title   : fetch_by_Name
 Usage   : $obj->fetch_by_Name
 Function: 
 Example : 
 Returns :array of seqtag objects
 Args    :seqtag name or alias


=cut





sub fetch_by_Name {

    my ($self,$lib_id,$name)=@_;
 
    $self->throw("need a library id") unless  $lib_id;
    $self->throw("need a tag name") unless  $name;

    
    my $multiplier=$self->multiplier; 

    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency,
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa,
                          library l 
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id  
                   and    l.library_id=f.library_id and l.library_id=$lib_id and s.name='$name' group by s.seqtag_id";


    return $self->_fetch($statement);  
    
    
}



=head2 fetch_by_Name_with_allAliases

 Title   : fetch_by_Name_with_allAliases
 Usage   : $obj->fetch_by_Name_with_allAliases
 Function: 
 Example : 
 Returns :array of seqtag objects
 Args    :seqtag name or alias


=cut



sub fetch_by_Name_with_allAliases {

    my ($self,$name)=@_;
    
    $self->throw("need a tag name") unless  $name;   

    my $statement="select s.name,sa.external_name, sa.db_name 
                   from   seqtag s,seqtag_alias sa  
                   where  sa.seqtag_id=s.seqtag_id  and s.name='$name'";

    return $self->_fetch_aliases($statement);  
    
    
}






sub fetch_by_Synonym_with_allAliases_1 {

    my ($self,$synonym)=@_;
 
#    $self->throw("need a library id") unless  $lib_id;
    $self->throw("need a tag synonym") unless  $synonym;

   
  #  my $multiplier=$self->multiplier; 

  #  my $statement="select s.seqtag_id,s.source,s.name,
  #                        sa1.db_name,sa1.external_name,f.frequency,
  #                        ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
  #                 from   seqtag s,frequency f,seqtag_alias sa1, seqtag_alias sa2,
  #                        library l 
  #                 where  s.seqtag_id=f.seqtag_id and sa1.seqtag_id=s.seqtag_id and sa1.seqtag_id=sa2.seqtag_id 
  #                 and    l.library_id=f.library_id and l.library_id=$lib_id and sa2.external_name='$synonym'";


#    my $statement="select t.name,s1.external_name,s1.db_name 
#                   from   seqtag_alias s1,seqtag_alias s2,seqtag t  
#                   where  s1.seqtag_id=s2.seqtag_id and t.seqtag_id=s1.seqtag_id  
#                   and    s2.external_name='$synonym'"; 

#    my $statement="select
#    return $self->_fetch_aliases($statement);  
    
    
}



=head2 fetch_by_Library_dbID

 Title   : fetch_by_Library_dbID
 Usage   : $obj->fetch_by_Library_dbID
 Function: 
 Example : 
 Returns : array of seqtag objects
 Args    : library id


=cut


sub fetch_by_Library_dbID 
{
    my ($self,$id)=@_;

    $self->throw("need a library id") unless  $id;

   
    my $multiplier=$self->multiplier; 
    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency, 
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa,
                          library l  
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id 
                   and    l.library_id=f.library_id and f.library_id='$id'";

    return $self->_fetch($statement); 
}


=head2 fetch_by_Library_dbID_SeqTag_dbID

 Title   : fetch_by_Library_dbID_SeqTag_dbID
 Usage   : $obj->fetch_by_Library_dbID_SeqTag_dbID
 Function: 
 Example : 
 Returns : array of seqtag objects
 Args    : library id,seqtag db id


=cut


sub fetch_by_Library_dbID_SeqTag_dbID 
{
    my ($self,$library_id,$id)=@_;

    $self->throw("need a library id") unless  $library_id;
    $self->throw("need a seqtag id") unless  $id;

   
    my $multiplier=$self->multiplier; 
    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency, 
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa,
                          library l  
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id 
                   and    l.library_id=f.library_id and f.library_id='$library_id' and s.seqtag_id=$id";

    return $self->_fetch($statement); 
}






=head2 fetch_by_Library_Name

 Title   : fetch_by_Library_Name
 Usage   : $obj->fetch_by_Library_Name
 Function: 
 Example : 
 Returns : array of seqtag objects
 Args    : library name


=cut




sub fetch_by_Library_Name 
{
    my ($self,$name)=@_;

  $self->throw("need a library name") unless  $name;

   
    my $multiplier=$self->multiplier; 
    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency,    
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa,
                          library l  
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id 
                   and    l.library_id=f.library_id and l.name='$name'";

    return $self->_fetch($statement);

}




=head2 fetch_by_LibraryList_dbIDs

 Title   : fetch_by_LibraryList_dbID
 Usage   : $obj->fetch_by_LibraryList_dbID
 Function: 
 Example : 
 Returns : array of seqtag objects
 Args    : array of library ids


=cut




sub fetch_by_LibraryList_dbIDs 
{
    my ($self,@ids)=@_;

    $self->throw("need a list of library ids") unless  @ids && $#ids>=0;
    
    my $list=$self->_prepare_list(@ids);

    unless ($list){
	return ();
    }
           
   
    my $multiplier=$self->multiplier; 
    my $statement="select   s.seqtag_id,s.source,s.name,
                            sa.db_name,sa.external_name,f.frequency, 
                            ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from     seqtag s,frequency f,seqtag_alias sa,
                            library l  
                   where    s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id 
                   and      l.library_id=f.library_id and f.library_id in $list limit 10";

   
    return $self->_fetch($statement); 


}


=head2 fetch_by_LibraryList_Name

 Title   : fetch_by_LibraryList_Name
 Usage   : $obj->fetch_by_LibraryList_Name
 Function: 
 Example : 
 Returns : array of seqtag objects
 Args    : array of library names


=cut



sub fetch_by_LibraryList_Name 
{
    my ($self,@ids)=@_;

    $self->throw("need a list of library ids") unless  @ids && $#ids>=0;
    
    my $list=$self->_prepare_list(@ids);
    
    unless ($list){
	return ();
    }
    
   
    my $multiplier=$self->multiplier; 

    my $statement="select s.seqtag_id,s.source,s.name,
                          sa.db_name,sa.external_name,f.frequency,    
                          ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa,
                          library l   
                   where  s.seqtag_id=f.seqtag_id and sa.seqtag_id=s.seqtag_id 
                   and    l.library_id=f.library_id and l.name in $list";
    
    return $self->_fetch($statement);


}


=head2  fetch_by_Library_dbID_above_frequency

 Title   : fetch_by_Library_dbID_above_frequency
 Usage   : $obj->fetch_by_Library_dbID_above_frequency
 Function: this method is supposed to be used from LibraryAdaptor
 Example : 
 Returns : array of seqtag objects above absolute frequency
 Args    : libray id, frequency


=cut


sub fetch_by_Library_dbID_above_frequency {
    my ($self,$id,$frequency)=@_;



    $self->throw("need a library id") unless  $id;
    $self->throw("need a frequency value") unless  $frequency;

   
    my $multiplier=$self->multiplier; 

    my $statement="select s.seqtag_id,s.source,s.name,sa.db_name,sa.external_name,f.frequency,
                   ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from   seqtag s,frequency f,seqtag_alias sa 
                   where  s.seqtag_id=f.seqtag_id 
                   and    sa.seqtag_id=s.seqtag_id 
                   and    f.library_id='$id' and f.frequency>$frequency";


    return $self->_fetch($statement);  


}




=head2  fetch_by_Library_dbID_above_relative_frequency

 Title   : fetch_by_Library_dbID_above_relative_frequency
 Usage   : $obj->fetch_by_Library_dbID_above_relative_frequency
 Function: this method is supposed to be used from LibraryAdaptor
 Example : 
 Returns : array of seqtag objects above relative frequency
 Args    : libray id, frequency


=cut


sub fetch_by_Library_dbID_above_relative_frequency {
    my ($self,$id,$frequency,$multiplier)=@_;

    $self->throw("need a library id") unless  $id;
    $self->throw("need a frequency value") unless  $frequency;
    $multiplier=$self->multiplier unless $multiplier; 
   
    my $statement="select   s.seqtag_id,s.source,s.name,sa.db_name,sa.external_name,f.frequency,  
                            ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from     seqtag s,frequency f,library l,seqtag_alias sa  
                   where    s.seqtag_id=f.seqtag_id                                    
                   and      l.library_id=f.library_id 
                   and      sa.seqtag_id=s.seqtag_id 
                   and      f.library_id='$id' and  
                            ceiling((f.frequency*$multiplier/l.total_seqtags) -1)>$frequency
                   order by relative_frequency desc";


    return $self->_fetch($statement);  

}


=head2  fetch_by_Library_dbID_below_relative_frequency

 Title   : fetch_by_Library_dbID_below_relative_frequency
 Usage   : $obj->fetch_by_Library_dbID_below_relative_frequency
 Function: this method is supposed to be used from LibraryAdaptor
 Example : 
 Returns : array of seqtag objects below relative frequency
 Args    : libray id, frequency


=cut


sub fetch_by_Library_dbID_below_relative_frequency {
    my ($self,$id,$frequency,$multiplier)=@_;

    $self->throw("need a library id") unless  $id;
    $self->throw("need a frequency value") unless  $frequency;
    $multiplier=$self->multiplier unless $multiplier; 
   

    my $statement="select   s.seqtag_id,s.source,s.name,sa.db_name,sa.external_name,f.frequency,  
                            ceiling((f.frequency*$multiplier/l.total_seqtags) -1) as relative_frequency
                   from     seqtag s,frequency f,library l,seqtag_alias sa  
                   where    s.seqtag_id=f.seqtag_id                                    
                   and      l.library_id=f.library_id 
                   and      sa.seqtag_id=s.seqtag_id 
                   and      f.library_id='$id' and  
                            ceiling((f.frequency*$multiplier/l.total_seqtags) -1)<$frequency
                   order by relative_frequency desc";


    return $self->_fetch($statement);  

}




=head2 multiplier

 Title   : multiplier
 Usage   : $obj->multiplier($newval)
 Function: 
 Example : 
 Returns : value of multiplier
 Args    : newvalue (optional)


=cut

sub multiplier {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_multiplier'} = $value;
  } elsif (!defined$obj->{'_multiplier'})  {
      $obj->{'_multiplier'}=1000000;
  }
    return $obj->{'_multiplier'};
}



sub _list {
 my ($self,$statement)=@_;
 my @tag_ids;
 my $sth = $self->prepare($statement);    
 $sth->execute();

 while (my $nm=$sth->fetchrow_array){
     push @tag_ids,$nm;
 }

 return @tag_ids;
}



sub _fetch {

    my ($self,$statement)=@_;

    my @tags;
    my $sth = $self->prepare($statement);    
    $sth->execute();
    
    my ($library_id,$source,$name,$db,$external_name,$frequency,$relative_frequency);

    $sth->bind_columns(undef,\$library_id,\$source,\$name,\$db,\$external_name,\$frequency,\$relative_frequency);

    while ($sth->fetch){	
	my @args=($library_id,$source,$name,$frequency,$relative_frequency);	
	my $tg=Bio::EnsEMBL::ExternalData::Expression::SeqTag->new($self,@args);
	push @tags,$tg;
	
	my $link = new Bio::Annotation::DBLink;
	$link->database($db);
	$link->primary_id($external_name);
	$tg->add_DBLink($link);
	
    }    
    return @tags;    
}






sub _fetch_aliases {

    my ($self,$statement)=@_;

    my @tags;
    my $sth = $self->prepare($statement);    
    $sth->execute();
    
    my ($name,$external_name,$db);

    $sth->bind_columns(undef,\$name,\$external_name,\$db);

    while ($sth->fetch){	
	my ($library_id,$source,$frequency,$relative_frequency);
	my @args=($library_id,$source,$name,$frequency,$relative_frequency);	
	my $tg=Bio::EnsEMBL::ExternalData::Expression::SeqTag->new($self,@args);
	push @tags,$tg;
	
	my $link = new Bio::Annotation::DBLink;
	$link->database($db);
	$link->primary_id($external_name);
	$tg->add_DBLink($link);
	
    }    
    return @tags;    
}















sub _prepare_list {
    my ($self,@ids)=@_;
    
    my $string;
    foreach my $id(@ids){
	$string .= $id . ","; 
    }
    chop $string;
    
    if ($string) { $string = "($string)";} 

    return $string;
    
}















