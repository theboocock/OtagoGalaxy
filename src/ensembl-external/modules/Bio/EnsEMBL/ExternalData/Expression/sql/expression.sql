# MySQL dump 5.13
#
# Host: localhost    Database: expression
#--------------------------------------------------------
# Server version	3.23.25-beta

#
# Table structure for table 'frequency'
#
CREATE TABLE frequency (
  seqtag_id int(10) unsigned DEFAULT '0' NOT NULL,
  library_id int(10) unsigned DEFAULT '0' NOT NULL,
  frequency float,
  KEY (seqtag_id),
  KEY (library_id),
  PRIMARY KEY (seqtag_id,library_id)
);

#
# Table structure for table 'key_word'
#
CREATE TABLE key_word (
  key_id int(10) unsigned NOT NULL auto_increment,
  key_word varchar(20) DEFAULT '' NOT NULL,
  PRIMARY KEY (key_id),
  KEY key_word (key_word)
);

#
# Table structure for table 'lib_key'
#
CREATE TABLE lib_key (
  library_id int(10) DEFAULT '0' NOT NULL,
  key_id int(5) DEFAULT '0' NOT NULL,
  PRIMARY KEY (library_id,key_id)
);

#
# Table structure for table 'library'
#
CREATE TABLE library (
  library_id int(10) unsigned NOT NULL auto_increment,
  source int(10),
  cgap_id int(10),
  dbest_id int(10),
  name varchar(80) NOT NULL,
  tissue_type varchar(225) DEFAULT '' NOT NULL,
  description mediumtext,
  total_seqtags int(10),
  KEY (name),
  PRIMARY KEY (library_id)
);

#
# Table structure for table 'seqtag'
#
CREATE TABLE seqtag (
  seqtag_id int(10) unsigned NOT NULL auto_increment,
  source int(10),
  name varchar(15) default '' not null,
  PRIMARY KEY (seqtag_id),
  KEY name (name)
);

#
# Table structure for table 'seqtag_alias'
#
CREATE TABLE seqtag_alias (
  seqtag_id int(10) unsigned NOT NULL auto_increment,
  db_name varchar(20) DEFAULT '' NOT NULL,
  external_name varchar(20) DEFAULT '' NOT NULL,
  KEY seqtag_id (seqtag_id),
  KEY db_name (db_name),
  KEY external_name (external_name),
  PRIMARY KEY (seqtag_id,db_name,external_name)	
);

#
# Table structure for table 'source'
#
CREATE TABLE source (
  source_id int(10) unsigned DEFAULT '0' NOT NULL,
  source_name varchar(20),
  assay varchar(20),
  PRIMARY KEY (source_id)
);









