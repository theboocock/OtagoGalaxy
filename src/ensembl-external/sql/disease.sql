# MySQL dump 7.1
#
# Host: localhost    Database: disease
#--------------------------------------------------------
# Server version	3.22.32

#
# Table structure for table 'disease'
#
CREATE TABLE disease (
  id int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  disease varchar(160),
  PRIMARY KEY (id)
);

#
# Table structure for table 'disease_index_doclist'
#
CREATE TABLE disease_index_doclist (
  id mediumint(8) unsigned DEFAULT '0' NOT NULL auto_increment,
  n mediumint(8) unsigned DEFAULT '0' NOT NULL,
  PRIMARY KEY (id)
);

#
# Table structure for table 'disease_index_stoplist'
#
CREATE TABLE disease_index_stoplist (
  id mediumint(8) unsigned DEFAULT '0' NOT NULL auto_increment,
  word varchar(32) binary DEFAULT '' NOT NULL,
  PRIMARY KEY (id),
  UNIQUE word (word)
);

#
# Table structure for table 'disease_index_vectorlist'
#
CREATE TABLE disease_index_vectorlist (
  wid mediumint(8) unsigned DEFAULT '0' NOT NULL,
  did mediumint(8) unsigned DEFAULT '0' NOT NULL,
  f float(10,4) DEFAULT '0.0000' NOT NULL,
  UNIQUE wid (wid,did)
);

#
# Table structure for table 'disease_index_wordlist'
#
CREATE TABLE disease_index_wordlist (
  id mediumint(8) unsigned DEFAULT '0' NOT NULL auto_increment,
  word varchar(32) binary DEFAULT '' NOT NULL,
  PRIMARY KEY (id),
  UNIQUE word (word)
);

#
# Table structure for table 'gene'
#
CREATE TABLE gene (
  id int(10) DEFAULT '0' NOT NULL,
  gene_symbol varchar(30) DEFAULT '' NOT NULL,
  omim_id int(10),
  start_cyto varchar(20),
  end_cyto varchar(20),
  chromosome varchar(5)
);

#
# Table structure for table 'last_update'
#
CREATE TABLE last_update (
  disease timestamp(14),
  indexes timestamp(14)
);

