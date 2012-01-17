
#
# Ensembl module for Bio::EnsEMBL::ExternalData::SNPSQL::WebAdaptor.pm
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::SNPSQL::WebAdaptor - Web accelerated (light objects) for SNPs

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION


This object is derived from SNPSQL::DBAdaptor.

Method get_Ensembl_SeqFeatures_clone_web() is there only to speed up
Web work. It loads only minimal set of sequence features into
Variation objects . To get a fullset of Variation attributes method
get_SeqFeature_by_id() is call on select objects, only. Additionally
it needs an attribute determined by the display resolution on how far
apart the features have to be to be drawn. 


=head1 AUTHOR - Ewan Birney

This modules is part of the Ensembl project http://www.ensembl.org

Email birney@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::ExternalData::SNPSQL::WebAdaptor;
use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::Variation;
use Bio::EnsEMBL::Utils::Eprof qw( eprof_start eprof_end);


@ISA = qw(Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor);


# new is inherieted from SNPSQL::DBAdaptor

=head2 get_Ensembl_SeqFeatures_clone_web

 Title   : get_Ensembl_SeqFeatures_clone_web
 Usage   :
 Function:
 Example :
 Returns : a list of lightweight Variation features.
 Args    : scalar in nucleotides (should default to 50)
           array of accession.version numbers

=cut

sub get_Ensembl_SeqFeatures_clone_web {
    my ($self,$glob,@acc) = @_;
    
    if (! defined $glob) {
        $self->throw("Need to call get_Ensembl_SeqFeatures_clone_web with a globbing parameter and a list of clones");
    }
    if (scalar(@acc) == 0) {
        $self->throw("Calling get_Ensembl_SeqFeatures_clone_web with empty list of clones!\n");
    }
    
    #lists of variations to be returned
    my @variations;
    my %hash;
    my $string;
    foreach my $a (@acc) {
        $a =~ /(\S+)\.(\d+)/;
        $string .= "'$1',";
        $hash{$1}=$2;
    }
    $string =~ s/,$//;
    my $inlist = "($string)";
    
    # db query to return all variation information in current GoldenPath; confidence attribute is gone!!
    # data are preprocessed to contain only relevent information (RefSNP.mapweight  is not needed)
    # denormalized SubSNP in

    my $query = qq{

        SELECT   start, end, strand,
                 acc, version, refsnpid,
                 tcsid, hgbaseid
        FROM   	 GPHit
        WHERE  	 acc in $inlist
	ORDER BY acc,start    

              };

    &eprof_start('snp-sql-query');

    my $sth = $self->prepare($query);
    my $res = $sth->execute();

    &eprof_end('snp-sql-query');

    my $snp;
    my $cl;

    &eprof_start('snp-sql-object');

  SNP:
    while( (my $arr = $sth->fetchrow_arrayref()) ) {
        
        my ($begin, $end, $strand,
            $acc, $ver, $snpuid,
            $tscid, $hgbaseid
           ) = @{$arr};
        
        my $acc_version="$acc.$ver";
	if ( defined $snp && $snp->end+$glob >= $begin && $acc_version eq $cl) {
            #ignore snp within glob area
            next SNP;
        }
        
        next SNP if $hash{$acc} != $ver;
        #
        # prepare the output objects
        #
        
        ### mega dodginess here: ideally, a Variation should be allowed to
        ### have several Locations. However, a Variation is-a SeqFeature,
        ### which can only have one. So instead, we'll return a list of
        ### Varations, each with a separate single location, but otherwise
        ### identical. That's clean-room engineering for you :-) 
        
        my $key=$snpuid.$acc;           # for purpose of filtering duplicates
        my %seen;                       # likewise
        
        
        if ( ! $seen{$key} )  {
            ## we're grabbing all the necessary stuff from the db in one
            ## SQL statement for speed purposes, so we have to do some
            ## duplicate filtering here.

            $seen{$key}++;
            
            #Variation
            $snp = new Bio::EnsEMBL::ExternalData::Variation
              (-start => $begin,
               -end => $end,
               -strand => $strand,
               -original_strand => $strand,
               -score => 1,
               -source_tag => 'dbSNP',
              );
            
            my $link = new Bio::Annotation::DBLink;
            $link->database('dbSNP');
            $link->primary_id($snpuid);
            $link->optional_id($acc_version);
            #add dbXref to Variation
            $snp->add_DBLink($link);
	    if ($hgbaseid) {
	      my $link2 = new Bio::Annotation::DBLink;
	      $link2->database('HGBASE');
	      $link2->primary_id($hgbaseid);
	      $link2->optional_id($acc_version);
	      $snp->add_DBLink($link2);
	    }
	    if ($tscid) {
	      my $link3 = new Bio::Annotation::DBLink;
	      $link3->database('TSC-CSHL');
	      $link3->primary_id($tscid);
	      $link3->optional_id($acc_version);
	      #add dbXref to Variation
	      $snp->add_DBLink($link3);
	    }
            $cl=$acc_version;
            # set for compatibility to Virtual Contigs
            $snp->seqname($acc_version);
            #add SNP to the list
            push(@variations, $snp);
        }                               # if ! $seen{$key}
      }                                    # while a row from select statement

    &eprof_end('snp-sql-object');
    
    return @variations;
}
