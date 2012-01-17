#ifndef VARIATION_DATASTRUCTURE
#define VARIATION_DATASTRUCTURE

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <math.h>
#include <cstring>

using namespace std;

#define GSL_DLL
#include <gsl/gsl_sys.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <gsl/gsl_cdf.h>
#include <gsl/gsl_sf.h>
#include <gsl/gsl_fit.h>

typedef struct POPHAP //here we do not allow for different block sizes between populations, and thus blockSizes are not defined here
{	vector<int> Code; //coding of haplotypes
	vector<int> CFreq, UFreq; //hap freqs in cases or controls, 1-to-1 mapping to Code
} POPHAP;

typedef struct POPTREE
{	int parent;
	vector<int> children;
	vector<POPHAP> pop; //include pophap data for all loci
	vector<bool> status; //locus status
	vector<double> llp, intllp;
	bool used;
	double markerPrior, branchMarkerPrior;
} POPTREE;

typedef struct MYPARA
{	vector<vector<int> > blocks; //[n][2], [i][0]: block position, [i][1]: block size
	vector<POPHAP> hapCn; //haplotype counts in each block
	vector<POPHAP> refhapCn; //haplotype counts in reference panel in each block
	vector<vector<int> > Imap; //code map of each individual to hapCn
	vector<vector<int> > refImap; //code map of each reference individiual to refhapCn
	vector<POPHAP> misshapCn; //haplotype counts for each untyped snp combined with typed and associated snps
	vector<vector<int> > missImap;//code map of each individual to misshapCn
	vector<POPHAP> missrefhapCn;
	vector<vector<int> > missrefImap;
	
	vector<double> minferability; //probability that this snp can be imputed using others within the block
	vector<int> mmember; //association group 0, 1, 2, this is for markers, not for blocks
	vector<int> marmarker; //list of marginally associated markers;
	POPHAP inthapCn; //haplotypes for interacting markers
	vector<int> intImap; //code map of each individual for interacting markers
	vector<int> intmarker; //list of interacting markers
	int blockMax, blockMin;
	int intMax, intMin;
	double p1, p2;
	bool isR; //whether use genoes for disease model when data are haplotypes?
} MYPARA;

typedef struct MYDATA
{	vector<vector<char> > data;
	vector<bool> istatus; //case (true) or control (false)
	vector<char> mstatus; //completely genotyped (0), partially genotyped (1),  or untyped (2), for markers, not for blocks
	vector<vector<bool> > missingStatus; //[sites][individuals], 0: not missing, 1: missing
	vector<vector<int> > mpos; //marker locations [0]:chr, [1] position
	int refN;
	vector<vector<vector<double> > > scores;
	vector<int> scoremap;
} MYDATA;

#define MINUSINFINITE -1000000000

#endif
