# $Id: Journal.pm,v 1.6 2002/10/22 07:45:11 lapp Exp $
#
# BioPerl module for Bio::Biblio::Journal
#
# Cared for by Martin Senger <senger@ebi.ac.uk>
# For copyright and disclaimer see below.

# POD documentation - main docs before the code

=head1 NAME

Bio::Biblio::Journal - Representation of a journal

=head1 SYNOPSIS

    $obj = new Bio::Biblio::Journal (-name => 'The Perl Journal',
				     -issn  => '1087-903X');
 --- OR ---

    $obj = new Bio::Biblio::Journal;
    $obj->issn ('1087-903X');

=head1 DESCRIPTION

A storage object for a journal.
See its place in the class hierarchy in
http://industry.ebi.ac.uk/openBQS/images/bibobjects_perl.gif

=head2 Attributes

The following attributes are specific to this class
(however, you can also set and get all attributes defined in the parent classes):

  abbreviation
  issn
  name
  provider       type: Bio::Biblio::Provider

=head1 SEE ALSO

=over

=item *

OpenBQS home page: http://industry.ebi.ac.uk/openBQS

=item *

Comments to the Perl client: http://industry.ebi.ac.uk/openBQS/Client_perl.html

=back

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
email or the web:

  bioperl-bugs@bioperl.org
  http://bugzilla.bioperl.org/

=head1 AUTHORS

Heikki Lehvaslaiho (heikki@ebi.ac.uk),
Martin Senger (senger@ebi.ac.uk)

=head1 COPYRIGHT

Copyright (c) 2002 European Bioinformatics Institute. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind.

=cut


# Let the code begin...

package Bio::Biblio::Journal;
use strict;
use vars qw(@ISA);

use Bio::Biblio::BiblioBase;

@ISA = qw(Bio::Biblio::BiblioBase);

#
# a closure with a list of allowed attribute names (these names
# correspond with the allowed 'get' and 'set' methods); each name also
# keep what type the attribute should be (use 'undef' if it is a
# simple scalar)
#
{
    my %_allowed =
	(
	 _abbreviation => undef,
	 _issn => undef,
	 _name => undef,
	 _provider => 'Bio::Biblio::Provider',
	 );

    # return 1 if $attr is allowed to be set/get in this class
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr};
    }

    # return an expected type of given $attr
    sub _attr_type {
	my ($self, $attr) = @_;
	$_allowed{$attr};
    }
}

1;
__END__
