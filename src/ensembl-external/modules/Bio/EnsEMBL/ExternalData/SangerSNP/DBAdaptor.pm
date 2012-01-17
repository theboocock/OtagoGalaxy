package Bio::EnsEMBL::ExternalData::SangerSNP::DBAdaptor;

=head1 NAME

Bio::EnsEMBL::ExternalData::SangerSNP::DBAdaptor - 
Database adaptor for a SangerSNP database

=head1 SYNOPSIS

    $db_adaptor = Bio::EnsEMBL::ExternalData::SangerSNP::DBAdaptor->new(
        -user   => 'root',
        -pass   => 'secret',
        -dbname => 'pog',
        -host   => 'caldy',
        -driver => 'Oracle'
        );
    $snp_adaptor = $db_adaptor->get_SangerSNPAdaptor;
    
=head1 DESCRIPTION

This object represents a SangerSNP database. Once created you can retrieve object
adaptors that allow you to create objects from data in the SangerSNP database.
It delegates its connection responsibilities to the DBConnection class (no
longer inherited from) and its object adaptor retrieval to the static
Bio::EnsEMBL::Registry.

=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 AUTHORS

Steve Searle <searle@sanger.ac.uk>

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=cut

use strict;

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection;
use Bio::EnsEMBL::Utils::Exception qw(throw warning deprecate);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::DBSQL::DBAdaptor);

=head2 new

  Arg [-DNADB]: (optional) Bio::EnsEMBL::ExternalData::SangerSNP::DBAdaptor DNADB 
               All sequence, assembly, contig information etc, will be
               retrieved from this database instead.
  Arg [..]   : Other args are passed to
               Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection
  Exmaple    : $db = new Bio::EnsEMBL::ExternalData::SangerSNP::DBAdaptor(
                                                    -species => 'Homo_sapiens',
                                                    -group   => 'sangersnp'
						    -user    => 'root',
						    -dbname  => 'pog',
						    -host    => 'caldy',
						    -driver  => 'Oracle');
  Description: Constructor for DBAdaptor.
  Returntype : Bio::EnsEMBL::ExternalData::SangerSNP::DBAdaptor
  Exceptions : none
  Caller     : general

=cut

sub new {
    my($class, @args) = @_;
    my $self ={};
    bless $self,$class;

    $self->dbc(new Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection(@args));

    my ($species, $group, $con, $dnadb) =
        rearrange([qw(SPECIES GROUP DBCONN DNADB)], @args);

    if(defined($con)){
        $self->dbc($con);
    }
    else{
        $self->dbc(new Bio::EnsEMBL::ExternalData::SangerSNP::DBConnection(@args));
    }

    if(defined($species)){
        $self->species($species);
    }
    else{
        $self->species("DEFAULT");
    }
    if(defined($group)){
        $self->group($group);
    }

    $self = Bio::EnsEMBL::Utils::ConfigRegistry::gen_load($self);

    if(defined $dnadb) {
        $self->dnadb($dnadb);
    }

    return $self;
}

=head2 get_available_adaptors

  Example     : my %object_adaptors = %{ $dbadaptor->get_available_adaptors };
  Description : returns a lookup hash of object adaptors for this DBAdaptor
  Return type : Hashref
  Exceptions  : none
  Caller      : Bio::EnsEMBL::Utils::ConfigRegistry

=cut

sub get_available_adaptors{
  my %pairs = (
#    "SangerSNPBase"       => "Bio::EnsEMBL::ExternalData::SangerSNP::SangerSNPBaseAdaptor",
    "Variation"           => "Bio::EnsEMBL::ExternalData::SangerSNP::VariationAdaptor",
    "TranscriptVariation" => "Bio::EnsEMBL::ExternalData::SangerSNP::TranscriptVariationAdaptor",
  );
  return (\%pairs);
}

1;
