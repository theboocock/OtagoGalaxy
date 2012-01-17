# module Bio::EnsEMBL::ExternalData::Haplotype::Tag.pm
#
# Cared for by Pedro M. Gomez-Fabre <pgf18872@gsk.com>
#
# Copyright Pedro M. Gomez-Fabre
#
# You may distribute this module under the same term as perl itself
#

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::ExternalData::Haplotype::Tag.pm - Haplotype tag object.

=head1 SYNOPSIS

    use Bio::PopGen::Haplotype::Tag;

    my $obj = Tag -> new($hap);

=head1 DESCRIPTION

    This module take as input a haplotype and try toe get the minimal
set of SNP that define the haplotype. This module can be use alone.
But due to the tagging haplotype process is exponential one. My
suggestion is that before to use this module you pass your data under
Select.mp module also on this folder.  In any case if, you provide an
haplotype the module will try to find the answer to your question.

=head1 CONSTRUCTORS

    my $obj = Tag -> new($hap);

    were $hap is the reference to an array of array with the haplotype.

    $hap= [[0, 0, 0],
           [1, 0, 0],
           [0, 1, 1]
          ];
 
=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.bioperl.org/

=head1 AUTHOR - Pedro M. Gomez-Fabre

Email pedro.fabre-at-gen.gu.se

=cut

#

# Let the code begin...

package Bio::EnsEMBL::ExternalData::Haplotype::Tag;
use vars qw(@ISA);

use strict;

use Data::Dumper;
use Storable qw(dclone);


=head2 new

 Title   : new
 Function: constructor of the class.
 Returns : self hash
 Args    : input haplotype (array of array)
 Status  : public

=cut

#------------------------
sub new{
#------------------------
    my $class = shift;
    my $self ={};

    $self->{'input_block'} = shift;

    # make the calculation
    $self->{'tag_list'} = _scan_snp( $self->{'input_block'} );


    if ( $self->{'tag_list'}){

        $self->{'tag_length'} = scalar @{ $self->{'tag_list'}->[0] };
    }
    else {
        $self->{'tag_length'} = "NO TAGS FOUND!";
    }

    bless $self, $class;

    return $self;
}

=head2 input_block 

 Title   : input_block 
 Usage   : $obj->input_block()
 Function: constructor of the class.
 Returns : reference to array of array with the haplotype input value 
 Args    : none 
 Status  : public

=cut

#------------------------
sub input_block{
#------------------------
    my $self = shift;
    return $self->{input_block};
}

=head2 tag_list

 Title   : tag_list 
 Usage   : $obj->tag_list()
 Function: returns the list of SNPs combination that identify the
           haplotype. All combinations are displayed as arrays
 Returns : reference to array of array. 
 Args    : none
 Status  : public

=cut

#------------------------
sub tag_list{
#------------------------
    my $self = shift;
    return $self->{tag_list};
}

=head2 tag_length 

 Title   : tag_length 
 Usage   : $obj->tag_length()
 Function: returns the length of the tag.
 Returns : scalar 
 Args    : none
 Status  : public

=cut

#------------------------
sub tag_length{
#------------------------
    my $self =shift;

    return $self->{tag_length};
}

=head2 _scan_snp 

 Title   : _scan_snp 
 Usage   : internal
 Function: scan sets increasing the length until find a non degenerated
           pattern. 
 Returns : scalar
 Args    : none
 Status  : private

=cut

#------------------------
sub _scan_snp{
#------------------------
    my ($hap)=@_;

    my $hap_length = scalar @{$hap->[0]};    ## store the haplotype length

    for my $i(1..$hap_length){

        my $list = _gen_comb($hap_length, $i);

        my $snp_collection = _scan_combinations($hap, $list);

        # if there is any element on the collection.
        # We have reached our goal and 
        # we can stop the calculation.
        if($#$snp_collection>-1){
            return $snp_collection;
        }
    }
}

=head2 _gen_comb

 Title   : _gen_comb 
 Usage   : internal
 Function: we supply the length of the haplotype and the length of the
           word we need to find and the functions returns the possible
           list of combinations.
 Returns : scalar
 Args    : none
 Status  : private

=cut

#------------------------
sub _gen_comb{
#------------------------

    my ($hap_length,$n) = @_;

    my @array = ();    # list with all elements we have to combine

    
    for(0..$hap_length-1){ push @array, $_ };

    #
    # we need some parameters to create the combination list.
    # This parameters can be changed if we can modify the list values
    #

    my $m = -1;      # this parameter start the calculation at value
                     # m+1 on the recursive cicle.

    my $value = [];  ## seems to hve not too much sense here, but is
                     ## needed on the recursion and need to be started
                     ## from here
    my $list = [];

    _generateCombinations ( \@array, \$m, \$n, $value, $list);

    return $list;

}

=head2 _generateCombinations 

 Title   : _generateCombinations 
 Usage   : internal
 Function: Recursive function that produce all combinations for a set

           i.e.:

           1, 2, 3, 4

           and word of B<3> will produce:

           1, 2, 3
           1, 2, 4
           1, 3, 4
           2, 3, 4
 
 Returns :
 Args    : none
 Status  : private

=cut

#------------------------
sub _generateCombinations{
#------------------------
    my ($rarr, $rm, $rn, $rvalue,$rlist)=@_;

    for (my $i = ($$rm+1); $i<scalar @$rarr; $i++){
        push (my @value2,@$rvalue,$rarr->[$i]);
        if (scalar @value2<$$rn){
            _generateCombinations($rarr,\$i, $rn, \@value2, $rlist);
        }
        if (scalar @value2==$$rn){
            push @$rlist, [@value2];
        }
        if(scalar @value2>$$rn){
            last;
        }
    }
}

# take the list of combinations
# i.e.: 1 2 3
#       1 2 4
#       1 3 4
#       2 3 4
#
# generate a sub array from the haplotype with the snp tag for the combination
# and check all haplotypes for these columns.
# if two haplotypes have the same value. we can not define the haplotype
# without ambiguity.
# Will return a list of valid combinations (SNP Tags)
#

=head2 _scan_combinations 

 Title   : _scan_combinations 
 Usage   : internal
 Function: take the haplotype and a list of possible combination
           for that length. Generate a subset and scan it to find if
           the information is enought to define the haplotype set.
 Returns :
 Args    : none
 Status  : private

=cut

#------------------------
sub _scan_combinations {
#------------------------

    my($hap,$list) = @_;

    my $valid_combination = undef;

    # we have to check every snp combinations from the list
    for my $i (0..$#$list){

        # extract from the big array the one we will use for tag calculations
        my $subArray = _get_subArray ($hap, $list->[$i]);

        my $degeneration = _deg_test($subArray);

        if(!$degeneration){
            push @$valid_combination, [@{$list->[$i]}];
        }
    }
    return $valid_combination;
}

# return 1 if two arrays are degenerated (same haplotype)
#------------------------
sub _deg_test{
#------------------------

    my ($hap)= @_;

    # for every sub array we compare each element with the rest
    for my $c1(0..$#$hap){
        for my $c2($c1+1..$#$hap){
            my $degeneration = compare_arrays($hap->[$c1], $hap->[$c2]);
            if ($degeneration){
                # if the two arrays are the same
                return 1;
            }
        }
    }
}

#------------------------
sub _get_subArray {
#------------------------
    my($hap, $combination) =@_;

    my $out = [];    # output array to be tested
 
    for my $i (0..$#$hap){
        foreach(@$combination){
            push @{$out->[$i]}, $hap->[$i][$_];
        }
    }
    return $out;
}

#
# take two arrays and compare their values
# Returns : 1 if the two values are the same
#           0 if the values are different
#

#------------------------
sub compare_arrays {
#------------------------
    my ($first, $second) = @_;
    return 0 unless @$first == @$second;
    for (my $i = 0; $i < @$first; $i++) {
        return 0 if $first->[$i] ne $second->[$i];
    }
    return 1;
}

1;
