The evsClient.jar is a java package for running batch-mode query to the Exome Variant Server (EVS) (http://snp.gs.washington.edu/EVS). 

------------
Requirements
------------
    Java 6 JVM.

----------
How to Use
----------
    java -jar YOUR_DOWNLOADED_evsClient.jar -h


******************************************************************************
**************************** EVS Batch Query Client **************************
******************************************************************************
The program is used to query exome variants from the EVS database,
Cammand Line: 
    java -jar YOUR_DOWNLOADED_evsClient.jar -t YOUR_TARGET -f OUTPUT_FILE_FORMAT
Valid options:
    -t, --target    : query target (REQUIRED)
                      allowed values: N:Start-Stop (a chromosome region)
                                     (N=1-22,x,y; maxium range per query: 1,000,000)
                              or     GeneName (gene HUGO name)
                              or     GeneID (NCBI Gene ID)
    -f, --format    : output file format for varaints
                      allowed values: text, or vcf
                      Default: text
    -h, --help      : Displays this help text.

Examples: 
    Query a gene by gene HUGO name:  java -jar evsClient.jar -t actb

    Query a gene by NCBI Gene ID:    java -jar evsClient.jar -t 79001

    Query a chromosome region   :    java -jar evsClient.jar -t 1:1000000-1100000

    Output variants in VCF format:   java -jar evsClient.jar -t actb -f vcf


