
/*

local_tables_generic.sql

DIFFERENCE from local_tables_human.sql:

 * Skip HGVS tables
 * For the table b$build_SNPContigLocusId_$genome
      > Skipping mrna_pos, mrna_start, mrna_stop

USE dbsnp.pl WITH THE runscript COMMAND TO REPLACE:

$build with --build option (Example: 131)
$genome with --genome option (Example: 37_1)
$genome_long with --genome-long (Example: GRCh37)

THIS SCRIPT REQUIRES THE FOLLOWING dbSNP TABLES EXIST IN THE DATABASE

Allele
AlleleFreqBySsPop
Batch
GeneIdToName
GtyFreqBySsPop
LocTypeCode
Method
MethodClass
Population
SNP
SNPSubSNPLink
SnpFunctionCode
SubSNP
UniGty
UniVariation
b$build_ContigInfo_$genome
b$build_SNPContigLoc_$genome
b$build_SNPContigLocusId_$genome
b$build_SNPMapInfo_$genome

*/

/* ADD INDEXES TO dbSNP Tables */


ALTER TABLE b$build_SNPContigLocusId_$genome ADD INDEX i_locus_id (locus_id);
ALTER TABLE Batch ADD INDEX i_batch_id (batch_id);
ALTER TABLE SubSNP ADD INDEX i_snp_id (snp_id);
ALTER TABLE SubSNP ADD INDEX i_batch_id (batch_id);


/* Now add custom tables, views and functions
   
  * Do not change the order of the tables defined within the code -
    some tables depend on others.

  * I've tried to arrange the order in terms of procesing flow at dbSNP,
    and various "tasks" that we want to accomplish with the database:
    
    Submission
    Experimental Details
    Validation
    Classification
    Sample Information
    Alleles and Frequency Data
    Genome Mapping
    Genes and Function
    Flanking Sequence (currently no local tables)
    Summary Information

  * LOCAL TABLES (alphabetical)

    _loc_allele_freqs
    _loc_alleles_top_strand
    _loc_functional_representative
    _loc_genotype_freqs
    _loc_maf
    _loc_snp_gene_list_ref
    _loc_snp_gene_ref
    _loc_snp_gene_rep_ref
    _loc_snp_summary
    _loc_submissions
    _loc_unique_mappings

  * FUNCTIONS
  
    _loc_f_translate

*/

-- FUNCTION _loc_f_translate: DNA "translation" function

DELIMITER $$

DROP FUNCTION IF EXISTS _loc_f_translate$$

CREATE FUNCTION _loc_f_translate
  (dna VARCHAR(255))
  RETURNS VARCHAR(255)
  DETERMINISTIC
BEGIN

  DECLARE i INT;
  DECLARE l INT;
  DECLARE trans VARCHAR(255);
  DECLARE base char(1);

  -- Loop through dna and convert

  SET l = LENGTH(dna);

  IF l=0 THEN
    RETURN '';
  END IF;

  SET i = 1;
  SET trans = ''; -- We will add translated bases to trans

  base_loop: LOOP
    SET base = SUBSTR(dna,i,1);

    -- Use CASE statement to translate the bases
    CASE base
      WHEN 'A' THEN SET trans = insert(trans,i,1,'T');
      WHEN 'T' THEN SET trans = insert(trans,i,1,'A');
      WHEN 'C' THEN SET trans = insert(trans,i,1,'G');
      WHEN 'G' THEN SET trans = insert(trans,i,1,'C');
      ELSE SET trans = insert(trans,i,1,base); -- Example: 'N' for missing nucelotide
    END CASE;

    IF i=l THEN
      LEAVE base_loop;
    END IF;

    SET i=i+1;
  END LOOP base_loop;

  RETURN trans;
END$$

DELIMITER ;


--
-- TASK: SUBMISSION
--


/* TABLE _loc_submissions

   Information on who submitted the SNP, and what data they included in the submission
*/

DROP TABLE IF EXISTS _loc_submissions;

CREATE TABLE _loc_submissions
SELECT SSS.subsnp_id,SSS.snp_id,SSS.build_id,SS.batch_id,
       SS.samplesize,SS.validation_status,B.handle,B.pop_id,
       P.loc_pop_id
  FROM SNPSubSNPLink SSS
  INNER JOIN SubSNP AS SS USING (subsnp_id) -- INNER JOIN: don't want it if it's not in SubSNP
  LEFT OUTER JOIN Batch AS B USING (batch_id)
  LEFT OUTER JOIN Population AS P USING (pop_id);

ALTER TABLE _loc_submissions ADD PRIMARY KEY (subsnp_id);
ALTER TABLE _loc_submissions ADD INDEX i_snp_id (snp_id);
ALTER TABLE _loc_submissions ADD INDEX i_batch_id (batch_id);
ALTER TABLE _loc_submissions ADD INDEX i_handle (handle);


--
-- TASK: EXPERIMENTAL DETAILS
--


/* TABLE _loc_methods */

DROP TABLE IF EXISTS _loc_methods;

CREATE TABLE _loc_methods
  SELECT ls.snp_id,ls.subsnp_id,ls.batch_id,
         m.handle,b.moltype,mc.name AS method_class_name,m.loc_method_id, b.samplesize,
	 m.seq_both_strands,m.mult_pcr_amplification,m.mult_clones_tested
  FROM _loc_submissions ls
  LEFT JOIN Batch b USING (batch_id)
  LEFT JOIN Method m ON (b.method_id = m.method_id)
  LEFT JOIN MethodClass mc ON (m.method_class = mc.meth_class_id);

ALTER TABLE _loc_methods MODIFY method_class_name
  ENUM('DHPLC','Hybridization','Computation','SSCP','Other','Unknown','RFLP','Sequence',
       'ClinicalSubmission;DHPLC','ClinicalSubmission;Hybridization','ClinicalSubmission;Computation',
       'ClinicalSubmission;SSCP','ClinicalSubmission;Other','ClinicalSubmission;Unknown',
       'ClinicalSubmission;RFLP','ClinicalSubmission;Sequence');

ALTER TABLE _loc_methods ADD PRIMARY KEY  (subsnp_id);
ALTER TABLE _loc_methods ADD INDEX i_snp_id (snp_id);


--
-- TASK: VALIDATION
--


/* TABLE _loc_validation

   Validation data, including average heterozygosity information, and # submissions
*/

DROP TABLE IF EXISTS _loc_validation;

CREATE TABLE _loc_validation
  SELECT snp_id,validation_status AS val_code,cnt_subsnp AS submissions,avg_heterozygosity AS het_avg,het_se
  FROM SNP;

ALTER TABLE _loc_validation ADD validation SET
  ('Cluster','Frequency','Submitter','DoubleHit','HapMap','1000Genomes');

UPDATE _loc_validation SET validation = val_code;
UPDATE _loc_validation SET validation = NULL WHERE val_code=0;
ALTER TABLE _loc_validation DROP val_code;
ALTER TABLE _loc_validation ADD PRIMARY KEY (snp_id);


--
-- TASK: CLASSIFICATION
--


/* TABLE: _loc_classification_ref

   For each snp_id, list the loc_type values (trueSNP, InsOnCtg, etc) where
   assembly = '$genome_long'

   *** Must check the following when updating the build:
   
     * The definition of the column 'snp_class' is consistent with what's in the
       table 'SnpClassCode'
       
     * The definition of the column 'loc_types' is consistent with what's in the
       table 'LocTypeCode'
*/

-- Create _tmp_class

DROP TABLE IF EXISTS _tmp_class;

CREATE TABLE _tmp_class
  SELECT S.snp_id,UV.subsnp_class AS snp_class
  FROM SNP S
  INNER JOIN UniVariation UV ON (S.univar_id = UV.univar_id);

ALTER TABLE _tmp_class MODIFY snp_class
  ENUM('Single Base','DIPS','Heterozygous','Microsatellite','Named SNP','No Variation','Mixed','Multi-Base');

ALTER TABLE _tmp_class ADD PRIMARY KEY (snp_id);

-- Create _tmp_loc_type, get loc_type.  Have seen multiple snp_id
-- values within $genome_long assembly - two different contigs or
-- something.

DROP TABLE IF EXISTS _tmp_loc_types;

CREATE TABLE _tmp_loc_types
  SELECT snp_id,GROUP_CONCAT(DISTINCT LTC.abbrev) AS loc_types
  FROM b$build_SNPContigLoc_$genome AS SCL
  INNER JOIN b$build_ContigInfo_$genome AS CI USING (ctg_id)
  INNER JOIN LocTypeCode AS LTC ON (SCL.loc_type = LTC.code)
  WHERE CI.group_label = '$genome_long'
  GROUP BY snp_id;

ALTER TABLE _tmp_loc_types MODIFY loc_types SET('InsOnCtg','trueSNP','DelOnCtg','LongerOnCtg','EqualOnCtg','ShorterOnCtg');
ALTER TABLE _tmp_loc_types ADD PRIMARY KEY (snp_id);

DROP TABLE IF EXISTS _loc_classification_ref;

CREATE TABLE _loc_classification_ref
  SELECT C.snp_id,C.snp_class,LT.loc_types
  FROM _tmp_class C
  JOIN _tmp_loc_types LT ON (C.snp_id = LT.snp_id);

ALTER TABLE _loc_classification_ref ADD PRIMARY KEY (snp_id);

DROP TABLE _tmp_class;
DROP TABLE _tmp_loc_types;


--
-- TASK: SAMPLE INFORMATION
--


/* TABLE _loc_sample_information

   List of samples for each pop_id
*/

DROP TABLE IF EXISTS _loc_sample_information;

CREATE TABLE _loc_sample_information
  SELECT P.pop_id,P.handle,P.loc_pop_id,
         SI.submitted_ind_id,SI.ind_id,SI.loc_ind_id,SI.loc_ind_alias,SI.loc_ind_grp,SI.ploidy
  FROM Population P
  INNER JOIN SubmittedIndividual SI ON (P.pop_id = SI.pop_id);

ALTER TABLE _loc_sample_information ADD INDEX (pop_id);








--
-- TASK: FREQUENCY DATA
--


/* TABLE _loc_allele_freqs

   Allele frequency data for each subsnp_id-snp_id-allele row. For
   example, frequency of "A" allele in Caucasians submitted by
   1000GENOMES in submission 100292
*/

DROP TABLE IF EXISTS _loc_allele_freqs;

CREATE TABLE _loc_allele_freqs
  SELECT sssl.snp_id,
        ss.subsnp_id,
        p.handle,p.pop_id,p.loc_pop_id,
        ls.samplesize,
        a.allele,
        ss.top_or_bot_strand,
        af.source,af.cnt,af.freq
  FROM SubSNP AS ss
  INNER JOIN SNPSubSNPLink sssl ON (ss.subsnp_id = sssl.subsnp_id)
  INNER JOIN AlleleFreqBySsPop AS af ON (ss.subsnp_id = af.subsnp_id) -- INNER JOIN - we only want rows with freq table
  LEFT OUTER JOIN Population AS p ON (af.pop_id = p.pop_id)
  LEFT OUTER JOIN _loc_submissions ls ON (ss.subsnp_id = ls.subsnp_id) -- ADDED 05-06-10 to get samplesize
  LEFT OUTER JOIN Allele AS a ON (af.allele_id = a.allele_id);

ALTER TABLE _loc_allele_freqs ADD UNIQUE INDEX i_allele (subsnp_id,pop_id,allele);
ALTER TABLE _loc_allele_freqs ADD INDEX i_snp_id (snp_id);
ALTER TABLE _loc_allele_freqs ADD INDEX i_subsnp_id (subsnp_id);

/* TABLE _loc_genotype_freqs

   Genotype frequency data for each subsnp_id-snp_id-allele row. For
   example, frequency of "A/G" genotype in Caucasians submitted by
   1000GENOMES in submission 100292

*/

DROP TABLE IF EXISTS _loc_genotype_freqs;

CREATE TABLE  _loc_genotype_freqs
  SELECT sssl.snp_id,
         ss.subsnp_id,
         p.handle,p.pop_id,p.loc_pop_id,
         ls.samplesize,
         ss.top_or_bot_strand,
         gf.unigty_id,
         ug.gty_str,
         gf.source,gf.cnt,gf.freq
  FROM SubSNP ss
  INNER JOIN SNPSubSNPLink sssl ON (ss.subsnp_id = sssl.subsnp_id)
  INNER JOIN GtyFreqBySsPop AS gf ON (ss.subsnp_id = gf.subsnp_id) -- INNER JOIN - we don't missing data from the freq table
  LEFT OUTER JOIN _loc_submissions ls ON (ss.subsnp_id = ls.subsnp_id) 
  LEFT OUTER JOIN UniGty ug ON (gf.unigty_id = ug.unigty_id)
  LEFT OUTER JOIN Population p ON (gf.pop_id = p.pop_id);

ALTER TABLE _loc_genotype_freqs ADD INDEX i_snp_id (snp_id);

/* TABLE _loc_maf

   Summary frequency data for each subsnp_id, pop_id row. Shows the
   alleles, minor allele, MAF, hardy-weinberg, etc, for that specific
   population.

   * Note that MAF=1 for monomorphic markers.

   * Uses a self-LEFT OUTER JOIN to grab the minor allele: see tables
     s1 and s2, which refer to _loc_allele_freqs.  The table s2 will
     be null in the outer null for the smallest allele due to the
     s1.freq > s2.freq. That is, s1.freq is not greater than any other
     allele.

   * IMPORTANT: It's tempting to use a NESTED SELECT instead of a
     TEMPORARY TABLE, but the issue is that the temporary table will
     not be indexed, and the query will either take forever or FAIL.
     I found that when using a temporary table and NO INDEX the query
     would hang indefinitely with status "Sending data" - you could
     see that there was absolutely no progress in the MySQL data
     directory (currently /mnt/mysql/mysql_data)

*/

/* TEMPORARY TABLE _tmp_allele_list

   List of all alleles for each subsnp_id-pop_id row
*/

DROP TABLE IF EXISTS _tmp_allele_list;

CREATE TABLE _tmp_allele_list
  SELECT laf.subsnp_id,laf.pop_id,GROUP_CONCAT(laf.allele ORDER BY laf.freq) AS alleles
  FROM _loc_allele_freqs AS laf
  GROUP BY laf.subsnp_id,laf.pop_id;

ALTER TABLE _tmp_allele_list ADD UNIQUE INDEX i_subsnp_id_pop_id (subsnp_id,pop_id);

/* TEMPORARY TABLE _tmp_maf

   This gets the MAF, but there may be duplicate subsnp_id-pop_id
   rows due to alleles with the same frequency, such as 0.5
*/

DROP TABLE IF EXISTS _tmp_maf;

CREATE TABLE _tmp_maf
  SELECT s1.snp_id,s1.subsnp_id,s1.handle,s1.pop_id,s1.loc_pop_id,s1.source,
         s1.allele AS minor_allele,
         s1.freq AS maf,
         s1.cnt, -- Added 04-08-10
         s1.top_or_bot_strand AS top_or_bot_strand_minor_allele
  FROM _loc_allele_freqs AS s1 
  LEFT OUTER JOIN _loc_allele_freqs AS s2 ON (s1.subsnp_id = s2.subsnp_id) AND (s1.pop_id = s2.pop_id) AND (s1.freq > s2.freq)
  WHERE s2.subsnp_id IS NULL;

ALTER TABLE _tmp_maf ADD INDEX i_subsnp_id_pop_id (subsnp_id,pop_id);

/* Now when there are alleles with the same frequency, such as 0.5, we
   select one alphabetically.  Also, merge in data from
   _tmp_allele_list and FreqSummaryBySsPop
*/

-- TABLE _loc_maf

DROP TABLE IF EXISTS _loc_maf;

CREATE TABLE _loc_maf
  SELECT s1.*,al.alleles,
         fs.chr_cnt,fs.ind_cnt,fs.non_founder_ind_cnt,
         fs.chisq,fs.df,fs.hwp FROM _tmp_maf AS s1
  LEFT OUTER JOIN _tmp_maf AS s2 ON (s1.subsnp_id = s2.subsnp_id) AND (s1.pop_id = s2.pop_id) AND (s1.minor_allele > s2.minor_allele)
  LEFT OUTER JOIN _tmp_allele_list AS al ON (s1.subsnp_id=al.subsnp_id AND s1.pop_id = al.pop_id)
  LEFT OUTER JOIN FreqSummaryBySsPop AS fs ON (s1.subsnp_id = fs.subsnp_id AND s1.pop_id = fs.pop_id)
  WHERE s2.subsnp_id IS NULL;

ALTER TABLE _loc_maf ADD UNIQUE INDEX i_subsnp_id_pop_id (subsnp_id,pop_id);
ALTER TABLE _loc_maf ADD INDEX i_snp_id (snp_id);

-- ADD COLUMN samplesize TO _loc_maf

ALTER TABLE _loc_maf ADD samplesize INTEGER AFTER non_founder_ind_cnt;
UPDATE _loc_maf LMAF
    LEFT OUTER JOIN _loc_submissions LS ON (LMAF.subsnp_id = LS.subsnp_id)
    SET LMAF.samplesize = LS.samplesize;

DROP TABLE _tmp_allele_list;
DROP TABLE _tmp_maf;

-- TEMPORARY PROCEDURE _tmp_p_make_allele_rows

DROP PROCEDURE IF EXISTS _tmp_p_make_allele_rows;

DELIMITER $$

CREATE PROCEDURE _tmp_p_make_allele_rows()

-- IN:  _tmp_alleles (pattern looks like "A/T" or "A/T/C")
-- OUT: _tmp_alleles2

BEGIN

DECLARE snp_id INTEGER;
DECLARE result VARCHAR(255);
DECLARE pattern_top VARCHAR(255);

DECLARE c CURSOR FOR SELECT * FROM _tmp_alleles;

DECLARE EXIT HANDLER FOR SQLSTATE '02000' BEGIN END;

OPEN c; -- Start up the cursor

myloop: LOOP

  FETCH C INTO snp_id,pattern_top;
  SET result = INSTR(pattern_top,'/');

  WHILE (result != 0) DO
    INSERT INTO _tmp_alleles2
      VALUES(snp_id,LEFT(pattern_top,result -1));

    SET pattern_top = SUBSTRING(pattern_top,result +1);
    SET result = INSTR(pattern_top,'/');

    IF result = 0 THEN
      INSERT INTO _tmp_alleles2
        VALUES(snp_id,pattern_top); -- The final allele
    END IF;
  END WHILE;

END LOOP;

CLOSE c;
END;
$$

DELIMITER ;

DROP TABLE IF EXISTS _tmp_alleles;

CREATE TABLE _tmp_alleles
  SELECT SS.snp_id,IF(SS.top_or_bot_strand='B',_loc_f_translate(O.pattern),O.pattern) AS pattern_top
  FROM SubSNP SS
  INNER JOIN ObsVariation O ON (SS.variation_id = O.var_id)
  WHERE SS.snp_id IS NOT NULL;

DROP TABLE IF EXISTS _tmp_alleles2;

CREATE TABLE _tmp_alleles2 (
  snp_id INTEGER,
  allele_top_strand VARCHAR(255)
);

-- Now convert to multiple rows using a stored procedure

CALL _tmp_p_make_allele_rows();
ALTER TABLE _tmp_alleles2 ADD INDEX (snp_id);

-- TABLE _loc_alleles_top_strand

-- See http://www.illumina.com/documents/products/technotes/technote_topbot.pdf

DROP TABLE IF EXISTS _loc_alleles_top_strand;

CREATE TABLE _loc_alleles_top_strand
  SELECT snp_id,GROUP_CONCAT(DISTINCT allele_top_strand ORDER BY allele_top_strand)
                AS alleles_top_strand
  FROM _tmp_alleles2
  GROUP BY snp_id;

ALTER TABLE _loc_alleles_top_strand ADD PRIMARY KEY (snp_id);

DROP TABLE _tmp_alleles;
DROP TABLE _tmp_alleles2;
DROP PROCEDURE _tmp_p_make_allele_rows;


--
-- TASK: GENOME MAPPING
--


/* TABLE loc_unique_mappings_ref

   Get mapping information for the refernce assembly for SNPs that map
   to a unique position (SNPContigLoc.weight=1)
     
   * Restricting to contigs where contig_start and contig_end is not null.
     Had an issue in build 131 with rs673 where weight=1 but for some reason
     there were multiple mappings from contigs where these columns were NULL - I
     don't know how dbSNP was caculating the coordinates if the contig didn't
     have mapping data.
*/

DROP TABLE IF EXISTS _loc_unique_mappings_ref;

CREATE TABLE _loc_unique_mappings_ref
       SELECT scl.snp_id, scl.ctg_id, scl.orientation, scl.asn_from, scl.asn_to,
              scl.asn_to - scl.asn_from + 1 AS num_bases,
              scl.aln_quality, scl.allele, scl.num_mism, scl.num_del, scl.num_ins,
              ci.contig_chr AS chr, scl.phys_pos_from + 1 AS pos_bp, ltc.abbrev AS loc_type_abbrev -- Add 1 to correct 0-based
       FROM b$build_SNPContigLoc_$genome AS scl
       INNER JOIN b$build_ContigInfo_$genome AS ci USING (ctg_id)           -- Discard SNPs with no ctg_id in ContigInfo
       INNER JOIN b$build_SNPMapInfo_$genome AS smi USING (snp_id)          -- Must have weight from SNPMapInfo
       LEFT OUTER JOIN LocTypeCode AS ltc ON scl.loc_type = ltc.code  -- Keep SNPs with missing loc_type
       WHERE ci.group_label='$genome_long'
         AND smi.assembly='$genome_long'
         AND smi.weight=1
         AND ci.contig_chr IS NOT NULL
         AND scl.phys_pos_from IS NOT NULL
	 AND ci.contig_start IS NOT NULL
	 AND ci.contig_end IS NOT NULL;

ALTER TABLE _loc_unique_mappings_ref MODIFY chr VARCHAR(2);
ALTER TABLE _loc_unique_mappings_ref MODIFY num_bases INTEGER;
ALTER TABLE _loc_unique_mappings_ref ADD PRIMARY KEY (snp_id);
ALTER TABLE _loc_unique_mappings_ref ADD INDEX i_chr (chr);
ALTER TABLE _loc_unique_mappings_ref ADD INDEX i_pos_bp (pos_bp);


--
-- TASK: GENES AND FUNCTION
--


/* TABLE _loc_snp_gene_ref

   SNP/Gene functional associations for the $genome_long assembly

   NOTE: (at least in build $build) fxn_class is never NULL and always matches a non-NULL SnpFunctionCode.code, so
         we can do an INNER JOIN without missing anything
	 
   * In build 131, for table b$build_SNPContigLocusId_$genome
     
      > Replacing mrna_pos with mrna_start, mrna_stop
     
      > For other organisms this may fail, so in local_tables_generic.sql omit these columns
*/

DROP TABLE IF EXISTS _loc_snp_gene_ref;

CREATE TABLE _loc_snp_gene_ref
  SELECT scli.snp_id,scli.ctg_id,scli.locus_id,gitn.gene_symbol,scli.mrna_acc,
         scli.fxn_class,fxn_codes.abbrev AS function,fxn_codes.is_coding,fxn_codes.is_exon,
         scli.reading_frame,scli.allele,scli.residue,scli.aa_position,scli.codon,scli.protRes
    FROM b$build_SNPContigLocusId_$genome AS scli
    INNER JOIN b$build_ContigInfo_$genome AS contigs USING (ctg_id) -- Must have contig info to get only $genome_long SNPs
    LEFT OUTER JOIN GeneIdToName AS gitn ON (scli.locus_id = gitn.gene_id) -- Get symbol, ok if can't find one
    INNER JOIN SnpFunctionCode AS fxn_codes ON (scli.fxn_class = fxn_codes.code)
    WHERE (contigs.group_label='$genome_long');

ALTER TABLE _loc_snp_gene_ref MODIFY snp_id INT NOT NULL;
ALTER TABLE _loc_snp_gene_ref MODIFY locus_id INT NOT NULL;
ALTER TABLE _loc_snp_gene_ref ADD INDEX i_snp_id (snp_id);
ALTER TABLE _loc_snp_gene_ref ADD INDEX i_locus_id (locus_id);
ALTER TABLE _loc_snp_gene_ref ADD INDEX i_gene_symbol (gene_symbol);

/* TABLE _loc_snp_gene_list_ref

   When there are multiple SNP/Gene association we show a list:

   snp_id,gene_function_list
   5842418, 'CHRNA4/nearGene-3,LOC100130587/intron'
   5857723, 'CHRNA9/intron'

   * IMPORTANT: the table _loc_snp_gene_ref must be created first
*/

DROP TABLE IF EXISTS _loc_snp_gene_list_ref;

CREATE TABLE _loc_snp_gene_list_ref (
  snp_id INTEGER UNSIGNED PRIMARY KEY,
  gene_function_list VARCHAR(1024)
);

INSERT INTO _loc_snp_gene_list_ref (snp_id,gene_function_list)
  SELECT snp_id,group_concat(DISTINCT concat(gene_symbol,'/',function) ORDER BY gene_symbol) AS gene_function_list
  FROM _loc_snp_gene_ref
  WHERE FUNCTION !='cds-reference'
  GROUP BY snp_id;

/* TABLE _loc_snp_gene_rep_ref

   A single SNP/GENE combination for every rs ID.  Function is prioritized according to
   the column 'score_annotation' in _loc_functional_representative

   * REQUIED TABLES:

     > _loc_snp_gene_ref
*/

/* REFERENCE TABLE: _loc_functional_representative

   This determines how we select snp/gene/function representatives

   --DO NOT DELETE--

   NOTE: originally used LOAD DATA statement to make this, then used mysqldump:

     mysqldump --compact --skip-extended-insert dbsnp_$build _loc_functional_representative >fr.sql
*/

DROP TABLE IF EXISTS _loc_functional_representative;

CREATE TABLE `_loc_functional_representative` (
  `code` tinyint(4) NOT NULL,
  `abbrev` varchar(20) default NULL,
  `descrip` varchar(255) default NULL,
  `score_annotation` tinyint(4) NOT NULL,
  PRIMARY KEY  (`code`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT INTO `_loc_functional_representative` VALUES (44,'frameshift','indel snp causing frameshift.',1);
INSERT INTO `_loc_functional_representative` VALUES (41,'nonsense','\"changes to STOP codon. ex.  rs328, TCA->TGA, Ser to terminator.\"',2);
INSERT INTO `_loc_functional_representative` VALUES (42,'missense','\"alters codon to make an altered amino acid in protein product. ex.  rs300, ACT->GCT, Thr->Ala.\"',3);
INSERT INTO `_loc_functional_representative` VALUES (75,'splice-5','5 prime donor dinucleotide. 1st two bases in the 5 prime end of the intron. Most intron starts is GU. ex.rs8424 is in donor site.',4);
INSERT INTO `_loc_functional_representative` VALUES (73,'splice-3','3 prime acceptor dinucleotide. The last two bases in the 3 prime end of an intron. Most intron ends with AG.ex.rs193227 is in acceptor site.',5);
INSERT INTO `_loc_functional_representative` VALUES (3,'cds-synon','\"synonymous change. ex. rs248, GAG->GAA, both produce amino acid: Glu\"',6);
INSERT INTO `_loc_functional_representative` VALUES (55,'UTR-5','5 prime untranslated region. ex.  rs1800590.',7);
INSERT INTO `_loc_functional_representative` VALUES (53,'UTR-3','3 prime untranslated region. ex.  rs3289.',8);
INSERT INTO `_loc_functional_representative` VALUES (6,'intron','intron. ex. rs249.',9);
INSERT INTO `_loc_functional_representative` VALUES (15,'nearGene-5','\"within 5'' 2kb to a gene. ex. rs7641128 is at NT_030737.9 pos7641128, with 2K bp of UTR starts 7641510 for NM_000237.2.\"',10);
INSERT INTO `_loc_functional_representative` VALUES (13,'nearGene-3','\"within 3'' 0.5kb to a gene. ex.  rs3916027  is at NT_030737.9 pos7669796, within 500 bp of UTR starts 7669698 for NM_000237.2.\"',11);
INSERT INTO `_loc_functional_representative` VALUES (1,'locus','mrna_acc and protein_acc both null.',99);
INSERT INTO `_loc_functional_representative` VALUES (2,'coding','coding',99);
INSERT INTO `_loc_functional_representative` VALUES (4,'cds-nonsynon','nonsynonymous change',99);
INSERT INTO `_loc_functional_representative` VALUES (5,'UTR','untranslated region',99);
INSERT INTO `_loc_functional_representative` VALUES (7,'splice-site','splice-site',99);
INSERT INTO `_loc_functional_representative` VALUES (8,'cds-reference','contig reference',99);
INSERT INTO `_loc_functional_representative` VALUES (9,'synonymy unknown','coding: synonymy unknown',99);
INSERT INTO `_loc_functional_representative` VALUES (11,'GeneSegment','In gene segment with null mrna and protein. ex. IGLV4-69. geneId=28784',99);

-- TEMPORARY TABLE: _tmp_big_func_rep - merge the score_annotation values with fxn_class

DROP TABLE IF EXISTS _tmp_big_func_rep;

CREATE TABLE _tmp_big_func_rep
  SELECT DISTINCT sgr.snp_id,sgr.fxn_class,fr.score_annotation
  FROM _loc_snp_gene_ref AS sgr
  INNER JOIN _loc_functional_representative AS fr ON (sgr.fxn_class = fr.code)
  WHERE (sgr.fxn_class != 8); -- fxn_class = 8: cds-reference

ALTER TABLE _tmp_big_func_rep ADD INDEX i_snp_id (snp_id);

/* TEMPORARY TABLE: _tmp_best_scores

   * For each snp_id group, take the row with the lowest score_annotation value

   * If the SNP has the same function with more than one gene, a random gene will be chosen as the
     representative - this is done when _loc_snp_gene_rep_ref is created
*/

DROP TABLE IF EXISTS _tmp_best_scores;

CREATE TABLE _tmp_best_scores
  SELECT BFR.snp_id, BFR.fxn_class,scoring.best_score_annotation
  FROM _tmp_big_func_rep AS BFR
  INNER JOIN (SELECT snp_id,MIN(score_annotation) AS best_score_annotation
    FROM _tmp_big_func_rep GROUP BY snp_id)
    AS scoring
    ON (BFR.snp_id = scoring.snp_id) AND (BFR.score_annotation = scoring.best_score_annotation);

ALTER TABLE _tmp_best_scores ADD INDEX i_snp_id (snp_id);

DROP TABLE IF EXISTS _loc_snp_gene_rep_ref;

CREATE TABLE _loc_snp_gene_rep_ref
  SELECT sgr.snp_id,sgr.gene_symbol AS rep_gene_symbol,
         sgr.locus_id AS rep_gene_id,mrna_acc AS rep_mrna_acc,
         sgr.function AS rep_function
         FROM _loc_snp_gene_ref AS sgr
  INNER JOIN _tmp_best_scores ON ( (sgr.snp_id = _tmp_best_scores.snp_id) AND (sgr.fxn_class = _tmp_best_scores.fxn_class) )
  GROUP BY snp_id; -- The GROUP BY modifier grabs a single snp/gene/function rep

ALTER TABLE _loc_snp_gene_rep_ref ADD PRIMARY KEY (snp_id);
ALTER TABLE _loc_snp_gene_rep_ref ADD INDEX i_gene_id (rep_gene_id);
ALTER TABLE _loc_snp_gene_rep_ref ADD INDEX i_gene_symbol (rep_gene_symbol);

DROP TABLE _tmp_big_func_rep;
DROP TABLE _tmp_best_scores;

--
-- Task: Summary Information
--


/* TABLE _loc_snp_summary

   PRIMARY KEY: snp_id
   
   As much summary data as we can show horizontally for each rs ID

   Columns
   --
   alleles_top_strand_freq: only those alleles observed with frequency data

   REQUIRED: _loc_allele_freqs
             _loc_f_translate()
*/

-- TEMPORARY TABLE _tmp_snp_ancestral_allele

DROP TABLE IF EXISTS _tmp_snp_ancestral_allele;

CREATE TABLE _tmp_snp_ancestral_allele
  SELECT SAA.snp_id,A.allele AS ancestral_allele
  FROM SNPAncestralAllele SAA
  INNER JOIN Allele A ON (SAA.ancestral_allele_id = A.allele_id);

ALTER TABLE _tmp_snp_ancestral_allele ADD PRIMARY KEY (snp_id);

-- TEMPORARY TABLE _tmp_allele_top_strand_freq, Get "TOP" alleles

DROP TABLE IF EXISTS _tmp_allele_top_strand_freq;

CREATE TABLE _tmp_allele_top_strand_freq
  SELECT snp_id,
  CASE top_or_bot_strand
    WHEN 'T' THEN allele
    WHEN 'B' THEN _loc_f_translate(allele)
    ELSE 'U'
  END AS allele_top_strand_freq
  FROM _loc_allele_freqs;

ALTER TABLE _tmp_allele_top_strand_freq ADD INDEX (snp_id);

-- TEMPORARY TABLE _tmp_allele_top_strand_freq
-- Now get the comma delimited list of alleles

DROP TABLE IF EXISTS _tmp_alleles_top_strand_freq;

CREATE TABLE _tmp_alleles_top_strand_freq
  SELECT snp_id,GROUP_CONCAT(DISTINCT allele_top_strand_freq ORDER BY allele_top_strand_freq) AS alleles_top_strand_freq
  FROM _tmp_allele_top_strand_freq
  GROUP BY snp_id;

ALTER TABLE _tmp_alleles_top_strand_freq ADD PRIMARY KEY (snp_id);

DROP TABLE IF EXISTS _tmp_1000_genomes;

CREATE TABLE _tmp_1000_genomes
  SELECT DISTINCT snp_id
  FROM _loc_submissions
  WHERE handle='1000GENOMES';

ALTER TABLE _tmp_1000_genomes ADD INDEX (snp_id);

-- TEMPORARY TABLE _tmp_hapmap

DROP TABLE IF EXISTS _tmp_hapmap;

CREATE TABLE _tmp_hapmap
  SELECT DISTINCT snp_id
  FROM _loc_submissions
  WHERE handle='CSHL-HAPMAP';

ALTER TABLE _tmp_hapmap ADD INDEX (snp_id);

-- TEMPORARY TABLE _tmp_methods
-- Get a list of Methods used from _loc_methods

DROP TABLE IF EXISTS _tmp_methods;

CREATE TABLE _tmp_methods
  SELECT snp_id,GROUP_CONCAT(method_class_name) AS methods
  FROM _loc_methods
  GROUP BY snp_id;

ALTER TABLE _tmp_methods MODIFY methods
  SET ('DHPLC','Hybridization','Computation','SSCP','Other','Unknown','RFLP','Sequence',
       'ClinicalSubmission;DHPLC','ClinicalSubmission;Hybridization','ClinicalSubmission;Computation',
       'ClinicalSubmission;SSCP','ClinicalSubmission;Other','ClinicalSubmission;Unknown',
       'ClinicalSubmission;RFLP','ClinicalSubmission;Sequence');
ALTER TABLE _tmp_methods ADD PRIMARY KEY (snp_id);

-- TEMPORARY TABLE _tmp_moltypes
-- Do the same thing for moltype - get a list of moltypes

DROP TABLE IF EXISTS _tmp_moltypes;

CREATE TABLE _tmp_moltypes
  SELECT snp_id,GROUP_CONCAT(DISTINCT moltype) AS moltypes
  FROM _loc_methods
  GROUP BY snp_id;

ALTER TABLE _tmp_moltypes MODIFY moltypes SET('Genomic','cDNA','NA');
ALTER TABLE _tmp_moltypes ADD PRIMARY KEY (snp_id);


-- TEMPORARY TABLE _tmp_build_ids;
-- Use this to create the column min_build_id

DROP TABLE IF EXISTS _tmp_build_ids;

CREATE TABLE _tmp_build_ids
    SELECT SSSL.snp_id,MIN(SSSL.build_id) AS min_build_id
    FROM SNPSubSNPLink SSSL
    GROUP BY snp_id;

ALTER TABLE _tmp_build_ids ADD PRIMARY KEY (snp_id);


/* TABLE _loc_snp_summary

   A big summary table based on the table  _loc_validation,
   which is taken from the table 'SNP' with no filtering
*/

DROP TABLE IF EXISTS _loc_snp_summary;

CREATE TABLE _loc_snp_summary
  SELECT V.snp_id,V.submissions,BIDS.min_build_id,MT.moltypes,M.methods,V.validation,C.snp_class,C.loc_types AS loc_types_ref,
         V.het_avg,V.het_se,
         ATS.alleles_top_strand,ATSF.alleles_top_strand_freq,SAA.ancestral_allele,
         U.ctg_id AS unique_ctg_id, U.chr AS unique_chr, U.pos_bp AS unique_pos_bp,
         S.rep_gene_symbol, S.rep_gene_id, S.rep_function, S.rep_mrna_acc,
         SMI.chr_cnt,SMI.contig_cnt,SMI.loc_cnt,SMI.weight AS map_info_weight,
         L.gene_function_list,
	 IF(1G.snp_id,1,0) AS sub_by_1000_genomes,
         IF(HM.snp_id,1,0) AS sub_by_hapmap
  FROM _loc_validation V
  LEFT JOIN _tmp_methods M ON (V.snp_id = M.snp_id)
  LEFT JOIN _tmp_moltypes MT ON (V.snp_id = MT.snp_id)
  LEFT JOIN _loc_classification_ref C ON (V.snp_id = C.snp_id)
  LEFT JOIN _loc_alleles_top_strand ATS ON (V.snp_id = ATS.snp_id)
  LEFT JOIN _tmp_alleles_top_strand_freq ATSF ON (V.snp_id = ATSF.snp_id)
  LEFT JOIN _tmp_snp_ancestral_allele SAA ON (V.snp_id = SAA.snp_id)
  LEFT JOIN _loc_unique_mappings_ref U ON (V.snp_id = U.snp_id)
  LEFT JOIN _loc_snp_gene_rep_ref S ON (V.snp_id = S.snp_id)
  LEFT JOIN b$build_SNPMapInfo_$genome SMI ON (V.snp_id = SMI.snp_id)
  LEFT JOIN _loc_snp_gene_list_ref L ON (V.snp_id = L.snp_id)
  LEFT JOIN _tmp_1000_genomes 1G ON (V.snp_id = 1G.snp_id)
  LEFT JOIN _tmp_hapmap HM ON (V.snp_id = HM.snp_id)
  LEFT JOIN _tmp_build_ids BIDS ON (V.snp_id = BIDS.snp_id)
  WHERE SMI.assembly='$genome_long';

ALTER TABLE _loc_snp_summary ADD PRIMARY KEY (snp_id);
ALTER TABLE _loc_snp_summary ADD INDEX i_rep_gene_id (rep_gene_id);
ALTER TABLE _loc_snp_summary ADD INDEX i_rep_gene_symbol (rep_gene_symbol);
ALTER TABLE _loc_snp_summary ADD INDEX i_chr_pos (unique_chr, unique_pos_bp);

DROP TABLE _tmp_snp_ancestral_allele;
DROP TABLE _tmp_allele_top_strand_freq;
DROP TABLE _tmp_alleles_top_strand_freq;
DROP TABLE _tmp_1000_genomes;
DROP TABLE _tmp_hapmap;
DROP TABLE _tmp_methods;
DROP TABLE _tmp_moltypes;
DROP TABLE _tmp_build_ids; 

