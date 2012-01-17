# $Id: family.sql,v 1.14 2003-04-07 10:16:36 abel Exp $

# Tables for protein family clustering.

CREATE TABLE family (
   family_id			int(10) NOT NULL auto_increment,
   stable_id			varchar(40) NOT NULL, # e.g. ENSF0000012345
   description			varchar(255) NOT NULL,
   release			varchar(10) NOT NULL,
   annotation_confidence_score	double, 

   PRIMARY KEY(family_id), 
   UNIQUE KEY(stable_id),
   KEY(description),
   KEY(release)
);

CREATE TABLE external_db (
  external_db_id	int(10) NOT NULL auto_increment,
  name varchar(40) 	NOT NULL,

  PRIMARY KEY(external_db_id),
  UNIQUE KEY(name)
);

CREATE TABLE family_members (
  family_member_id	int(10) NOT NULL auto_increment,
  family_id		int(10) NOT NULL, # foreign key from family table
  external_db_id        int(10) NOT NULL, # foreign key from external_db table 
  external_member_id	varchar(40) NOT NULL, # e.g. ENSP000001234 or P31946
  taxon_id		int(10) NOT NULL, # foreign key from taxon table
  alignment             text,

  PRIMARY KEY(family_member_id),
  UNIQUE KEY(family_id,external_db_id,external_member_id,taxon_id),
  KEY(external_db_id,external_member_id),
  KEY(external_db_id),
  KEY(family_id,external_db_id)
);

CREATE TABLE taxon (
  taxon_id		int(10) NOT NULL,
  genus			varchar(50),
  species	        varchar(50),
  sub_species		varchar(50),
  common_name		varchar(100),
  classification	mediumtext,

  PRIMARY KEY(taxon_id),
  KEY(genus,species),
  KEY(common_name)
);



#
# Table structure for table 'genome_db'
#

CREATE TABLE genome_db (
  genome_db_id int(10) NOT NULL auto_increment,
  taxon_id int(10) DEFAULT '0' NOT NULL,
  name varchar(40) DEFAULT '' NOT NULL,
  assembly varchar(255) DEFAULT '' NOT NULL,
  PRIMARY KEY (genome_db_id),
  UNIQUE name (name,assembly)
);


