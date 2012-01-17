#
# EnsEMBL module for Bio::EnsEMBL::ExternalData::Expression::ExpressionAdaptor
#
# Cared for by EnsEMBL (www.ensembl.org)
#
# Copyright GRL and EBI
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::Expression::LibraryAdaptor

=head1 SYNOPSIS

    my $dbname='expression';
    my $lib_ad=Bio::EnsEMBL::ExternalData::Expression::LibraryAdaptor->new($obj);
    $lib_ad->dbname($dbname);

    # pass in a list of synonyms
    my @libs=$lib_ad->fetch_by_SeqTag_SynonymList("ENSG00000080561"); 

    my @tgs=("AAAAAAAAAA","AAAAAAAAAC");
    my @libs=$lib_ad->fetch_by_SeqTagList(@tgs);



=head1 DESCRIPTION

Represents information on one Clone

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


package Bio::EnsEMBL::ExternalData::Expression::LibraryAdaptor;
use Bio::EnsEMBL::ExternalData::BaseAdaptor;
use Bio::EnsEMBL::ExternalData::Expression::Library;
use Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor;
use vars qw(@ISA);
use strict;

@ISA = qw(Bio::EnsEMBL::ExternalData::BaseAdaptor);



# new in Bio::EnsEMBL::ExternalData::BaseAdaptor




=head2 fetch_all

 Title   : fetch_all
 Usage   : $obj->fetch_all
 Function: 
 Example : 
 Returns : array of library objects
 Args    : 


=cut




sub fetch_all {
    my ($self)=shift;

   
    my $statement="select library_id,source,cgap_id,
                          dbest_id,name,
                          tissue_type,description,total_seqtags
                   from   library";

    return $self->_fetch($statement);   

}


=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   : $obj->fetch_by_dbID
 Function: 
 Example : 
 Returns : library object
 Args    : 


=cut




sub fetch_by_dbID {
    my ($self,$id)=@_;
    
    $self->throw("need a library id") unless $id; 
   
    my $statement="select library_id,source,cgap_id,
                          dbest_id,name,
                          tissue_type,description,total_seqtags
                   from   library where library.library_id=$id";

    my @libs=$self->_fetch($statement);   
    
    if (defined $libs[0]){
	return $libs[0];
    }else{return;}
    

}


=head2 fetch_by_Name

 Title   : fetch_by_Name
 Usage   : $obj->fetch_by_Name
 Function: 
 Example : 
 Returns : library object
 Args    : 


=cut




sub fetch_by_Name {
    my ($self,$name)=@_;
    
    $self->throw("need a library name") unless $name; 
   
    my $statement="select library_id,source,cgap_id,
                          dbest_id,name,
                          tissue_type,description,total_seqtags
                   from   library where library.name='$name'";

    my @libs=$self->_fetch($statement);   
    
    if (defined $libs[0]){
	return $libs[0];
    }else{return;}
    

}

=head2 fetch_by_SeqTag_Name

 Title   : fetch_by_SeqTag_Name
 Usage   : $obj->fetch_by_SeqTag_Name
 Function: 
 Example : 
 Returns : array of library objects
 Args    : seqtag name


=cut




sub fetch_by_SeqTag_Name {

    my ($self,$name)=@_;

    $self->throw("need a seqtag name") unless $name; 

   
    my $statement="select l.library_id,l.source,l.cgap_id,
                          l.dbest_id,l.name,
                          l.tissue_type,l.description,l.total_seqtags
                   from   library l,seqtag_alias a,frequency f 
                   where  l.library_id=f.library_id 
                   and    f.seqtag_id=a.seqtag_id
                   and    a.external_name='$name'"; 
            
    return $self->_fetch($statement); 


}



=head2 fetch_by_SeqTagList

 Title   : fetch_by_SeqTagList
 Usage   : $obj->fetch_by_SeqTagList
 Function: 
 Example : 
 Returns : array of library objects
 Args    : array of seqtag names


=cut




sub fetch_by_SeqTagList {

    my ($self,@seqtags)=@_;

    $self->throw("need a seqtag name") unless  @seqtags && $#seqtags>=0; 

    my $list=$self->_prepare_list(@seqtags);
   
    my $statement="select l.library_id,l.source,l.cgap_id,
                          l.dbest_id,l.name,
                          l.tissue_type,l.description,l.total_seqtags
                   from   library l,seqtag s,frequency f 
                   where  l.library_id=f.library_id 
                   and    f.seqtag_id=s.seqtag_id 
                   and    s.name in $list"; 
    
    print "$statement\n";

    return $self->_fetch($statement); 
    
    
}




=head2 fetch_by_SeqTag_SynonymList

 Title   : fetch_by_SeqTag_SynonymList
 Usage   : $obj->fetch_by_SeqTag_SynonymList
 Function: 
 Example : 
 Returns : array of library objects
 Args    : array of seqtag synonyms


=cut





sub fetch_by_SeqTag_SynonymList {

    my ($self,@seqtags)=@_;

    $self->throw("need a seqtag name") unless  @seqtags && $#seqtags>=0; 

    my $list=$self->_prepare_list(@seqtags);
   
    my $statement="select l.library_id,l.source,l.cgap_id,
                          l.dbest_id,l.name,
                          l.tissue_type,l.description,l.total_seqtags
                   from   library l,seqtag_alias a,frequency f 
                   where  l.library_id=f.library_id 
                   and    f.seqtag_id=a.seqtag_id
                   and    a.external_name in $list"; 
            
    return $self->_fetch($statement); 
}




=head2 fetch_SeqTag_by_dbID

 Title   : fetch_SeqTag_by_dbID
 Usage   : $obj->fetch_SeqTag_by_dbID
 Function: 
 Example : 
 Returns : seqtag object
 Args    :


=cut


sub fetch_SeqTag_by_dbID {
    my ($self,$library_id,$id)=@_;

    $self->throw("need a library id") unless $library_id; 
    $self->throw("need a seqtag id") unless $id; 

    my $seqtag_ad=Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($self->db);
   
    
    my $seqtag=$seqtag_ad->fetch_by_Library_dbID_SeqTag_dbID($library_id,$id);
    if (defined $seqtag){
	return $seqtag;
    }else{
	return;
    }
}


=head2 fetch_SeqTag_by_Name

 Title   : fetch_SeqTag_by_Name
 Usage   : $obj->fetch_SeqTag_by_Name
 Function: 
 Example : 
 Returns : seqtag object
 Args    :


=cut


sub fetch_SeqTag_by_Name {
    my ($self,$library_id,$synonym)=@_;
    
    $self->throw("need a library id") unless $library_id; 
    $self->throw("need a seqtag synonym") unless $synonym; 

    my $seqtag_ad=Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($self->db);
   
    
    return $seqtag_ad->fetch_by_Name($library_id,$synonym);
   
}



=head2 fetch_all_SeqTags

 Title   : fetch_all_SeqTags
 Usage   : $obj->fetch_all_SeqTags
 Function: 
 Example : 
 Returns : array of seqtags objects
 Args    :


=cut


sub fetch_all_SeqTags {
    my ($self,$id)=@_;

    $self->throw("need a library id") unless $id; 

    my $seqtag_ad=Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($self->db);
   
    return $seqtag_ad->fetch_by_Library_dbID($id);

}



=head2 fetch_all_SeqTags_above_frequency

 Title   : fetch_all_SeqTags_above_frequency
 Usage   : $obj->fetch_all_SeqTags_above_frequency
 Function: returns seqtags with expression above given level 
 Example : 
 Returns : array of seqtags objects
 Args    :


=cut





sub fetch_all_SeqTags_above_frequency {
    my ($self,$id,$frequency)=@_;

    $self->throw("need a library id") unless $id; 
    $self->throw("need a frequency value") unless $frequency;

    my $seqtag_ad=Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($self->db);
   
    return $seqtag_ad->fetch_by_Library_dbID_above_frequency($id,$frequency);

}




=head2 fetch_all_SeqTags_above_relative_frequency

 Title   : fetch_all_SeqTags_above_relative_frequency
 Usage   : $obj->fetch_all_SeqTags_above_realtive_frequency
 Function: returns seqtags with expression above given level 
 Example : 
 Returns : array of seqtags objects
 Args    :


=cut



sub fetch_all_SeqTags_above_relative_frequency {
    my ($self,$id,$frequency,$multiplier)=@_;

    $self->throw("need a library id") unless $id; 
    $self->throw("need a frequency value") unless $frequency;
    $multiplier=$self->multiplier unless $multiplier; 

    my $seqtag_ad=Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($self->db);
   
    return $seqtag_ad->fetch_by_Library_dbID_above_relative_frequency($id,$frequency,$multiplier);

}


=head2 fetch_all_SeqTags_below_relative_frequency

 Title   : fetch_all_SeqTags_below_relative_frequency
 Usage   : $obj->fetch_all_SeqTags_below_realtive_frequency
 Function: returns seqtags with expression below given level 
 Example : 
 Returns : array of seqtags objects
 Args    :


=cut



sub fetch_all_SeqTags_below_relative_frequency {
    my ($self,$id,$frequency,$multiplier)=@_;

    $self->throw("need a library id") unless $id; 
    $self->throw("need a frequency value") unless $frequency;
    $multiplier=$self->multiplier unless $multiplier; 


    my $seqtag_ad=Bio::EnsEMBL::ExternalData::Expression::SeqTagAdaptor->new($self->db);
   
    return $seqtag_ad->fetch_by_Library_dbID_below_relative_frequency($id,$frequency);

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



sub _fetch {

    my ($self,$statement)=@_;

    my @libs;
    my $sth = $self->prepare($statement);    
    $sth->execute();
    
    my ($library_id,$source,$cgap_id,$dbest_id,
	$name,$tissue_type,$description, $total_seqtags);

    $sth->bind_columns(undef,\$library_id,\$source,\$cgap_id,\$dbest_id,
		   \$name,\$tissue_type,\$description,\$total_seqtags);

    while ($sth->fetch){	
	my @args=($library_id,$source,$cgap_id,$dbest_id,$name,$tissue_type,$description,$total_seqtags);	
	push @libs,Bio::EnsEMBL::ExternalData::Expression::Library->new($self,@args);
    }
    
    return @libs;
    
}




sub _prepare_list {
    my ($self,@ids)=@_;
    
    my $string;
    foreach my $id(@ids){
	$string .= $id . "\',\'"; 
    }

    $string="\'".$string;
       
    chop $string;
    chop $string;

    if ($string) { $string = "($string)";} 

    return $string;
    
}








































