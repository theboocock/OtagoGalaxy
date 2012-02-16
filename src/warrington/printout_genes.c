/*
 * =====================================================================================
 *
 *       Filename:  printout_genes.c
 *
 *    Description:  This program takes 2 files and in one pass determines
 *    		    whether the list goes to the print out
 *
 *        Version:  1.0
 *        Created:  16/11/11 15:07:36
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  James Boocock and Edward Hills
 * 
 *        Company: Otago University 
 *
 * =====================================================================================
 */
#define MAX_GENES 10000

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/*
 * compares two things
 */
int compare(const void* x, const void *y){
    const char **ix = (const char **) x;
    const char **iy = (const char **) y;
    return strcmp (*ix,*iy);
}

/*
 * binary searches for particular rs
 */
int search(char* rs, char ** genes,int start, int finish){
    int m =(finish + start) / 2;
    if(finish < start){
        return 0;
    }
    else if(strcmp(genes[m], rs) > 0){
        return search(rs, genes, start, m - 1);
    } else if(strcmp(genes[m],rs) < 0){
        return search(rs, genes, m + 1, finish);
    }else {
        return 1;
    }
}

/*
 * usage
 */
void usage(){
    printf("snpsearch [-opts] < bigfile.txt \n\n");
    printf("Options: \n\n");
    printf("-t [number] total number of participants and controls defaults to 0\n");
    printf("-n [number] total number of rsids in file we are interested in defaults to zero\n");
    printf("-i [filename] snps input file list\n");
    printf("-o [filename] output file\n");
}

/*
 * Main method scans through the genotype file given and then 
 * will search the snplist for the rsid. If it matches then that
 * line will be printed, otherwise it will be discarded.
 */ 
int main(int argc, char ** argv){
    int NUM_LINES = 0;
    FILE *toCheck = NULL; // large input file
    int num_genes = 0;
    char* genes[MAX_GENES]; // number of rsids in snplist
    char*  trash1;
    size_t len = 255;
    char check_against[150];
    char* subject;
    int i, j, index;
    extern char* optarg;
    extern int optind, optopt, opterr;
    int genes_to_print = 0;
    FILE* outputfile = NULL;
    int errflg = 0;
    int c;
    char * file;

    while((c = getopt(argc, argv, "ht:n:o:i:")) !=-1){
        switch(c){

            case 't':
                NUM_LINES = atoi(optarg);
                break;
            case 'o':
                if((outputfile = fopen(optarg, "w+")) == NULL){
                    fprintf(stderr, "File failed to open");
                    return EXIT_FAILURE;
                }
                break;
            case 'n':
                genes_to_print = atoi(optarg);
                break;
            case 'i':
                if((toCheck = fopen(optarg, "r")) == NULL){
                    fprintf(stderr,"File failed to open");
                    return EXIT_FAILURE;
                }
                break;
            case ':':
                printf("-%c without argument\n", optopt);
                break;
            case 'h':
                usage();
                exit(0);
                break;
            case '?':
                fprintf(stderr, "Unrecognized Option: -%c\n",optopt);
                errflg++;
        }
    }
    if(errflg){
        usage();
        exit(2);
    }


    file = malloc(len);
    while(getline(&file,&len,toCheck)){
        if(feof(toCheck) != 0){
            break;
        }
        file[strlen(file) - 1] = '\0';
        genes[num_genes] = malloc((strlen(file) + 1) * sizeof file[0]);
        strcpy(genes[num_genes++],file);
    }

    trash1 = malloc(sizeof(trash1[0]) * len); // trash1 is the long line of txt containg all information
    qsort(genes,genes_to_print ,sizeof(char *), compare); // make sure our list is sorted
    while(1){
        index = 0;
        // read in the first line
        if (getline(&trash1,&len,stdin) == -1) {
            break;
        }
        
        trash1[strlen(trash1) -1] = '\0';
        for(i = 0; trash1[i] !='\t'; i++){ // skip over patient id
        }
        if (trash1[i + 1] == 'r' || trash1[i + 1] == 'R') {
            for(j = i + 1; trash1[j] != '\t';j++){ // read up until next tab
                check_against[index++] = trash1[j];
            }
	    if (trash1[j+2] == '/' || trash1[j+2] == '\\') {
	      trash1[j+2] = '\t';
	    }
            // add a new line to end of string
            check_against[index] ='\0'; // add a end character to stringi
            if(search(check_against, genes,0,genes_to_print-1)){
                fprintf(outputfile,"%s\n",trash1); //print first line
            }
        }
    }
    // live free or die hard
    free(file);
    free(trash1);
    for(i = 0; i < genes_to_print; i++){
        free(genes[i]);
    }
    fclose(outputfile);
    fclose(toCheck);
    return 0;
}
