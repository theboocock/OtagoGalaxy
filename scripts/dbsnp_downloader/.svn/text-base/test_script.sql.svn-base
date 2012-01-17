
-- test_script.sql: use as --script option to runscript command

DROP TABLE IF EXISTS test_table;

CREATE TABLE test_table 
    SELECT ctg_id,tax_id FROM b$build_ContigInfo_$genome
    LIMIT 100;
