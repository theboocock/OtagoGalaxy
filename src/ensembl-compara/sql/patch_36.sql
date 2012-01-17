# ensembl_compara_36 was released without a schema_version entry
# in the meta table. This sql fixes it.
delete from meta where meta_key="schema_version";
insert into meta (meta_key,meta_value) values ("schema_version",36);
