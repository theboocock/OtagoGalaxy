# BioPerl Bio::Pipeline::FamilyConf
#
# configuration information

=head1 NAME
Bio::Pipeline::FamilyConf

=head1 DESCRIPTION
FamilyConf is a copy of humConf written by James Gilbert.

humConf is based upon ideas from the standard perl Env environment
module.

It imports and sets a number of standard global variables into the
calling package, which are used in many scripts in the human sequence
analysis system.  The variables are first decalared using "use vars",
so that it can be used when "use strict" is in use in the calling
script.  Without arguments all the standard variables are set, and
with a list, only those variables whose names are provided are set.
The module will die if a variable which doesn\'t appear in its
C<%FamilyConf> hash is asked to be set.

The variables can also be references to arrays or hashes.

All the variables are in capitals, so that they resemble environment
variables.

An additional hash C<%TaxonConf> holds the taxonomy classification.
The key value is the taxonomy id. This hash is used by
ensembl-external/family/scripts/dumpTranslation.pl when dumping the ensembl
peptides as a FASTA file and generating a description-like file.

=head1

=cut


package Bio::EnsEMBL::ExternalData::Family::FamilyConf;
use strict;
use vars qw(%FamilyConf %TaxonConf);


%FamilyConf = ( 

ENSEMBL_SPECIES => "HUMAN,RAT,MOUSE,FUGU,ZEBRAFISH,ANOPHELES,DROSOPHILA,ELEGANS,BRIGGSAE",

HUMAN_TAXON => "PREFIX=ENSP;taxon_id=9606;taxon_common_name=Human;taxon_classification=sapiens:Homo:Hominidae:Catarrhini:Primates:Eutheria:Mammalia:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

MOUSE_TAXON => "PREFIX=ENSMUSP;taxon_id=10090;taxon_common_name=Mouse;taxon_classification=musculus:Mus:Murinae:Muridae:Sciurognathi:Rodentia:Eutheria:Mammalia:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",,

RAT_TAXON => "PREFIX=ENSRNOP;taxon_id=10116;taxon_common_name=Norwayrat;taxon_classification=norvegicus:Rattus:Murinae:Muridae:Sciurognathi:Rodentia:Eutheria:Mammalia:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

FUGU_TAXON => "PREFIX=SINFRUP;taxon_id=31033;taxon_common_name=Japanese Pufferfish;taxon_classification=rubripes:Fugu:Takifugu:Tetraodontidae:Tetraodontiformes:Percomorpha:Acanthopterygii:Acanthomorpha:Neoteleostei:Euteleostei:Teleostei:Neopterygii:Actinopterygii:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

ZEBRAFISH_TAXON => "PREFIX=ENSDARP;taxon_id=7955;taxon_common_name=Zebrafish;taxon_classification=rerio:Danio:Cyprinidae:Cypriniformes:Ostariophysi:Teleostei:Neopterygii:Actinopterygii:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",
      
ANOPHELES_TAXON => "PREFIX=ENSANGP;taxon_id=7165;taxon_genus=Anopheles;taxon_species=gambiae;taxon_common_name=African malaria mosquito;taxon_classification=gambiae:Anopheles:Culicoidea:Nematocera:Diptera:Endopterygota:Neoptera:Pterygota:Insecta:Hexapoda:Arthropoda:Metazoa:Eukaryota",

DROSOPHILA_TAXON => "PREFIX=ENSDRMP;taxon_id=7227;taxon_genus=Drosophila;taxon_species=melanogaster;taxon_common_name=Fruit fly;taxon_classification=melanogaster:Drosophila:Drosophilidae:Ephydroidea:Muscomorpha:Brachycera:Diptera:Endopterygota:Neoptera:Pterygota:Insecta:Hexapoda:Arthropoda:Metazoa:Eukaryota",

ELEGANS_TAXON => "PREFIX=ENSCELP;taxon_id=6239;taxon_genus=Caenorhabditis;taxon_species=elegans;taxon_common_name=C.elegans;taxon_classification=elegans:Caenorhabditis:Peloderinae:Rhabditidae:Rhabditoidea:Rhabditida:Chromadorea:Nematoda:Metazoa:Eukaryota",

BRIGGSAE_TAXON => "PREFIX=ENSCBRP;taxon_id=6238;taxon_genus=Caenorhabditis;taxon_species=briggsae;taxon_common_name=C.briggsae;taxon_classification=briggsae:Caenorhabditis:Peloderinae:Rhabditidae:Rhabditoidea:Rhabditida:Chromadorea:Nematoda:Metazoa:Eukaryota",

FAMILY_PREFIX =>"ENSF",

FAMILY_START => 1,

EXTERNAL_DBNAME => "ENSEMBLPEP",

RELEASE => "10_1"

);

%TaxonConf = ( 

9606 => "taxon_id=9606;taxon_common_name=Human;taxon_classification=sapiens:Homo:Hominidae:Catarrhini:Primates:Eutheria:Mammalia:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

10090 => "taxon_id=10090;taxon_common_name=Mouse;taxon_classification=musculus:Mus:Murinae:Muridae:Sciurognathi:Rodentia:Eutheria:Mammalia:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

10116 => "taxon_id=10116;taxon_common_name=Norwayrat;taxon_classification=norvegicus:Rattus:Murinae:Muridae:Sciurognathi:Rodentia:Eutheria:Mammalia:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

31033 => "taxon_id=31033;taxon_common_name=Japanese Pufferfish;taxon_classification=rubripes:Fugu:Takifugu:Tetraodontidae:Tetraodontiformes:Percomorpha:Acanthopterygii:Acanthomorpha:Neoteleostei:Euteleostei:Teleostei:Neopterygii:Actinopterygii:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

7955 => "taxon_id=7955;taxon_common_name=Zebrafish;taxon_classification=rerio:Brachydanio:Danio:Cyprinidae:Cypriniformes:Ostariophysi:Teleostei:Neopterygii:Actinopterygii:Euteleostomi:Vertebrata:Craniata:Chordata:Metazoa:Eukaryota",

7165 => "taxon_id=7165;taxon_genus=Anopheles;taxon_species=gambiae;taxon_common_name=African malaria mosquito;taxon_classification=gambiae:Anopheles:Culicoidea:Nematocera:Diptera:Endopterygota:Neoptera:Pterygota:Insecta:Hexapoda:Arthropoda:Metazoa:Eukaryota",

7227 => "taxon_id=7227;taxon_genus=Drosophila;taxon_species=melanogaster;taxon_common_name=Fruit fly;taxon_classification=melanogaster:Drosophila:Drosophilidae:Ephydroidea:Muscomorpha:Brachycera:Diptera:Endopterygota:Neoptera:Pterygota:Insecta:Hexapoda:Arthropoda:Metazoa:Eukaryota",

6239 => "taxon_id=6239;taxon_genus=Caenorhabditis;taxon_species=elegans;taxon_common_name=C.elegans;taxon_classification=elegans:Caenorhabditis:Peloderinae:Rhabditidae:Rhabditoidea:Rhabditida:Chromadorea:Nematoda:Metazoa:Eukaryota",

6238 => "taxon_id=6238;taxon_genus=Caenorhabditis;taxon_species=briggsae;taxon_common_name=C.briggsae;taxon_classification=briggsae:Caenorhabditis:Peloderinae:Rhabditidae:Rhabditoidea:Rhabditida:Chromadorea:Nematoda:Metazoa:Eukaryota",

);

1;
