#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <math.h>
#include <cmath>

using namespace std;

#define GSL_DLL
#include <gsl/gsl_sys.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <gsl/gsl_cdf.h>
#include <gsl/gsl_sf.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_linalg.h>

typedef struct TARRAYRATIO
{	int chr, pos; //coding of haplotypes
	double ratio;
} TARRAYRATIO;

bool operator<(const TARRAYRATIO &a, const TARRAYRATIO &b)
{	if(a.chr < b.chr) return true;
	else if(a.chr == b.chr && a.pos <= b.pos) return true;
	else return false;
}

const gsl_rng_type *T;
gsl_rng *gammar;
vector<vector<double> > mAVG;
int PROBELENGTH;
int PROBEINTERV;
int PRESZ;
double minBound;

double lowerquantile = 0.05;
double upperquantile = 0.95;

typedef struct MYTYPE
{	double ratio;
	int index;
} MYTYPE;

bool operator<(const MYTYPE &a, const MYTYPE &b)
{	return a.ratio < b.ratio;	}

/////////////////////////////////////////////////////////////////////
void estimateP_maxpeak(vector<double> const &us, int winwidth, vector<vector<double> > const &cov, vector<vector<double> > const &cl, int repn, 
					   vector<double> const &predist, vector<double> const &sufdist, vector<vector<double> > const &lowerT, vector<vector<double> > &pvalues);
void getSums(vector<double> const &data, int maxWin, vector<vector<double> > &sums);
void declumpPeak(vector<TARRAYRATIO> &tar, int pos, int winwidth, vector<double> &removevalue, int &st, int &ed);
void identifyPeaks_maxpeak(vector<TARRAYRATIO> const &tar, vector<double> const &Lambdas, vector<vector<double> > const &thresholds, vector<vector<double> > &result, 
							vector<double> const &fplevels = vector<double>(), vector<vector<double> > const &preavg = vector<vector<double> >());
int _getLevels(vector<double> const &Lambdas, vector<double> const &fplevels, double upbound, int pos, int L, int curlevel);
void getLambdas(vector<double> const &priors, double totalLambda, double maxBound, vector<double> &lambdas, double &minl, double &maxl);
void estimateThresholds_theoretical_joint_withPriors(vector<TARRAYRATIO> const &tar, int wst, int wed, vector<double> const &priors, double totalLambda,
				vector<double> &Lambdas, vector<vector<double> > &thresholds, vector<double> &fplevels, vector<vector<double> > &cov, vector<vector<double> > &cl, int run);

void quantileNormalization(vector<TARRAYRATIO> &tar);
void test(vector<TARRAYRATIO> const &tar, double lambda, int wst, int wed, vector<double> &Lambdas, vector<vector<double> > &thresholds, vector<double> &priors, vector<vector<double> > &results);
void estimateStds(vector<TARRAYRATIO> const &tar, int width, vector<double> &avgstds);
void estimateCov(vector<TARRAYRATIO> const &tar, int range, int neighbor, vector<vector<double> > &cov, vector<vector<double> > &cl, double &mean, double &determinant);
void identifyPeaks_joint_rank(vector<TARRAYRATIO> const &tar, vector<vector<double> > const &thresholds, vector<vector<double> > &result, vector<vector<double> > const &preavg = vector<vector<double> >());
void getAverages(vector<TARRAYRATIO> const &tar, int st, int ed, int avgSz, vector<vector<double> > &averages);
void loadRatioData(char *filename, vector<TARRAYRATIO> &tar);
void normalizeData_withOutliers(vector<TARRAYRATIO> &tar, bool localmean);
void localCorrection(vector<TARRAYRATIO> &tar);
void estimateThresholds_theoretical2(vector<TARRAYRATIO> const &tar, int wst, int width, vector<double> const &lambdas, vector<double> &thresholds, double mean, vector<vector<double> > &cov, vector<vector<double> > &cl, bool joint, int run);
void _inverseLowerTriangularMatrix(vector<vector<double> > const &cl, vector<vector<double> > &il);
void getCoverDist(vector<TARRAYRATIO> const &tar, int width, vector<double> &coverdist, int &l);
void getSufDist(vector<TARRAYRATIO> const &tar, int width, vector<double> &sufdist);
void resizeCov(vector<vector<double> > const &orgcov, int nsz, vector<vector<double> > &cov);
void estimateThresholds_theoretical_joint(vector<TARRAYRATIO> const &tar, int wst, int wed, double minlambdaJ, double maxlambdaJ, int sz,
                                vector<double> &lambdas, vector<vector<double> > &thresholds, double &mean, vector<vector<double> > &cov, vector<vector<double> > &cl, int run);
void estimateP_IS_joint(vector<double> const &u, int width, double mean, vector<vector<double> > const &cl,
                  vector<vector<double> > &pvalues, vector<double> const &coverdist, vector<vector<double> > const &us, vector<double> const &sufdist, int run);
void estimateP_IS_jointnew(vector<double> const &u, int width, double mean, vector<vector<double> > const &cl,
		  vector<vector<double> > &pvalues, vector<double> const &coverdist, vector<vector<double> > const &us, vector<double> const &sufdist, int run);


void _choleskyDecomp(vector<vector<double> > const &cov, vector<vector<double> > &cl, double &determinant);
void _lm(vector<double> const &x, vector<double> const &y, double &alpha, double &beta);
//void _wlm(vector<double> const &x, vector<double> const &y, int id, double span, double &alpha, double &beta);
double _wlm(vector<double> const &x, vector<double> const &y, double xstar, double span, double &alpha, double &beta);
double _loess(vector<double> const &x, vector<double> const &y, double xstar, double span = 0.4, bool incorder = false);

double _scaler(vector<TARRAYRATIO> const &tar, double stds, double pst, double ped);

inline bool _validInterval(vector<TARRAYRATIO> const &tar, int pos, int sz)
{	return (sz <= 0 || (tar[pos].chr == tar[pos + sz].chr && abs(tar[pos + sz].pos - tar[pos].pos - PROBEINTERV * sz) <= max(PROBEINTERV * 4, 400))); }
inline bool _validCover(vector<TARRAYRATIO> const &tar, int pos1, int post)
{	return _validInterval(tar, pos1, post - pos1); }
/////////////////////////////////////////////////////////////////////

/*-------------------------------------------------*/
//command ./pass input wst wed lambda output
////////////////////////////
int main(int argc, char *argv[])
{
	gsl_rng_env_setup();
	T = gsl_rng_default;
	gammar = gsl_rng_alloc(T);
//	gsl_rng_set(gammar, (unsigned int)time(NULL) + 100 * clock());
	
	if(argc < 6)
	{	printf("Input format should be:\n./pass inputfile min_window max_window false_num outputfile [-qnorm] [-nop] [-adjust] [-p priorfile]\n");
		return 1;
	}

	//pass input wst wed lambda 
	int i;
	int wst = atoi(argv[2]);
	int wed = atoi(argv[3]);
	double lambda = atof(argv[4]);
	bool adjust = false;
	bool nop = false;
	char *output = argv[5];
	PRESZ = 20;
	minBound = 1.;

	vector<TARRAYRATIO> tar;
	loadRatioData(argv[1], tar);
/*for(i = 0; i < 300; i++)
{	int pp = (i+1)*2500;
	for(int j = pp - 6; j < pp + 7; j++) tar[j].ratio -= 10.;
}
for(i = 0; i < (int)tar.size(); i++) tar[i].ratio = gsl_ran_gaussian(gammar, 1.);
*/
/*for(i = 0; i < (int)tar.size(); i++)
{	tar[i].ratio = gsl_ran_gaussian(gammar, 1.);
}
for(i = 0; i < (int)tar.size(); i++)
    for(int j = 1; j < 6; j++)
		if(i + j < (int)tar.size()) tar[i].ratio += tar[i + j].ratio;
*/
/*FILE *tf = fopen("1.txt", "w");
for(i = 0; i < (int)tar.size(); i++)
fprintf(tf, "%d %d %f\n", tar[i].chr, tar[i].pos, tar[i].ratio);
fclose(tf);
*/

	if((int)tar.size() == 0)
	{	printf("Unable to load data from %s\n", argv[1]);
		return 1;
	}

	vector<double> priors;
	char *priorfile = NULL;
	char *threshfile = NULL;
	for(i = 6; i < argc; i++)
	{	if(i < argc - 1 && strcmp(argv[i], "-p")==0) 
		{	priorfile = argv[i + 1];
			i++;
		}
		else if(strcmp(argv[i], "-qnorm")==0) quantileNormalization(tar);
		else if(strcmp(argv[i], "-adjust")==0) adjust = true;
		else if(strcmp(argv[i], "-nop")==0) nop = true;
		else if(i < argc - 1 && strcmp(argv[i], "-threshfile")==0)
		{	threshfile = argv[i + 1];
			i++;
		}
	}
    if(priorfile != NULL)
	{	FILE *f = fopen(priorfile, "r");
		if(f == NULL) printf("Failed to load prior file \"%s\"\n", priorfile);
		else
		{	char tmp[100];
			while(fgets(tmp, 100, f) != NULL)
			{	if((int)strlen(tmp) >= 2) priors.push_back(atof(tmp));
			}
			fclose(f);
		}
	}
	
	if(!nop) normalizeData_withOutliers(tar, adjust);
/*tf = fopen("2.txt", "w");
for(i = 0; i < (int)tar.size(); i++)
fprintf(tf, "%d %d %f\n", tar[i].chr, tar[i].pos, tar[i].ratio);
fclose(tf);
*/
if(false)
{
FILE *f = fopen("tmp.txt", "w");
for(i = 0; i < (int)tar.size(); i++)
	fprintf(f, "%d\t%d\t%f\n", tar[i].chr, tar[i].pos, tar[i].ratio);
fclose(f);
exit(0);
}
	
	PROBELENGTH = 25;
	vector<int> dist;
	for(i = 0; i < min(10000, (int)tar.size()) - 1; i++)
		if(tar[i].chr == tar[i + 1].chr)
			dist.push_back(tar[i + 1].pos - tar[i].pos);
	sort(dist.begin(), dist.end());
	PROBEINTERV = dist[(int)dist.size() / 2];
	printf("# of probes = %d, probe interval = %d\n", (int)tar.size(), PROBEINTERV);fflush(stdout);

	FILE *f = fopen("thresholds.txt", "w");
	fclose(f);

	vector<vector<double> > mthresholds;
	vector<double> mlambdas;
	if(threshfile != NULL)
	{	char tmp[10000];
		f = fopen(threshfile, "r");
		if(f != NULL)
		{	while(fgets(tmp, 10000, f) != NULL)
			{	if((int)strlen(tmp) < 3) continue;
				mlambdas.push_back(atof(&tmp[0]));
				vector<double> ths;	
				for(int x = 1; x < (int)strlen(tmp) - 2; x++)
					if(tmp[x] == ' ' || tmp[x] == '\t')
					{	ths.push_back(atof(&tmp[x + 1]));
					}
				mthresholds.push_back(ths);
			}
			fclose(f);
		}
	}
	vector<vector<double> > results;
	test(tar, lambda, wst, wed, mlambdas, mthresholds, priors, results);

	f = fopen(output, "w");
	fprintf(f, "ID\tChr\tStart\t\tEnd\t\tWinSz\tPeakValue\t# of FPs\tFDR\n");
	vector<double> fdr((int)results.size(), 0);
	double psum = 0, fps = 0;
	for(i = 0; i < (int)priors.size(); i++) psum += priors[i];
	vector<int> spos;
	for(i = 0; i < (int)results.size(); i++)
	{	double ssum = 0;
		int j;
		if((int)spos.size() > 0)
		{	sort(spos.begin(), spos.end());
			for(j = 0; j < (int)spos.size(); j++)
			{	if(j == 0 || spos[j] != spos[j - 1]) ssum += priors[spos[j]];
			}
		}
printf("ssum=%f, psum=%f\n", ssum, psum);

		if(i == 0) fps = results[i][3] * (1. - ssum / psum);
		else fps += (results[i][3] - results[i - 1][3]) * (1. - ssum/psum);
		fdr[i] = fps / (double)(i + 1);
		for(j = (int)results[i][0]; j <= (int)results[i][1] && j < (int)tar.size(); j++)
			spos.push_back(j);
	}
	for(i = (int)fdr.size() - 2; i >= 0; i--)
		if(fdr[i] > fdr[i + 1]) fdr[i] = fdr[i + 1];

	for(i = 0; i < (int)results.size(); i++)
		fprintf(f, "%d\tchr%d\t%d\t%d\t%d\t%f\t%f\t%f\n", i + 1, tar[(int)results[i][0]].chr, tar[(int)results[i][0]].pos, tar[(int)results[i][1]].pos + PROBELENGTH, 
					(int)(results[i][1] - results[i][0]) + 1, results[i][2], results[i][3], fdr[i]);
	fclose(f);
	printf("Peak calling result is output to `%s'\n", output);	

	gsl_rng_free(gammar);
	return 0;
}

/*----------------------------------------------------------------------------------------------*/
void test(vector<TARRAYRATIO> const &tar, double lambda, int wst, int wed, vector<double> &Lambdas, vector<vector<double> > &thresholds, vector<double> &priors, vector<vector<double> > &results)
{
	vector<double> fplevels;
        if((int)priors.size() == 0)
                priors.resize((int)tar.size(), lambda / (double)tar.size());
 
	if((int)thresholds.size() == 0)
	{
		//vector<double> lambdas;
		//if(wst > 0) lambdas.resize(wst,0); 
		//lambdas.resize(wed, lambda / (double)(wed - wst + 1));
	
		int sz = 100;
		thresholds.resize(sz, vector<double>(wed, 1000000.));
		vector<vector<double> > cov, cl;
		double mean, determinant;
		vector<double> stds;
		estimateStds(tar, wed, stds);
		estimateCov(tar, wed + 2 * (PRESZ + wed - 1), -1, cov, cl, mean, determinant);
		int oPRESZ = PRESZ;
		for(PRESZ = 0; PRESZ < (int)cov.size(); PRESZ++)
			if(cov[PRESZ][0] < 0.05) break;
	
		if(PRESZ > oPRESZ) PRESZ = oPRESZ; 
		printf("buff = %d\n", PRESZ);
		FILE *f = fopen("thresholds.txt", "w");
		fclose(f);
	
		printf("finding thresholds...\n");fflush(stdout);
		estimateThresholds_theoretical_joint_withPriors(tar, wst, wed, priors, lambda, Lambdas, thresholds, fplevels, cov, cl, 20000);
		//else estimateThresholds_theoretical_joint(tar, wst, wed, lambda / (double)sz, lambda, sz, Lambdas, thresholds, mean, cov, cl, 20000);
		//for(int i = 0; i < (int)thresholds.size(); i++) for(int j = 0; j < (int)thresholds[i].size(); j++) thresholds[i][j] -= 0.1;
	}
	else
	{	if(wst > 1)
		{	vector<double> th(wst - 1, 1000000.);
			for(int i = 0; i < (int)thresholds.size(); i++)
				thresholds[i].insert(thresholds[i].begin(), th.begin(), th.end());
		}
		double minl, maxl;
		getLambdas(priors, lambda, lambda, fplevels, minl, maxl);
	}

	printf("detect peaks...");fflush(stdout);
	results.clear();
//	identifyPeaks_joint_rank(tar, thresholds, results);
FILE *ff = fopen("lambdas.txt", "w");
for(int i = 0; i < (int)Lambdas.size(); i++) fprintf(ff, "%f\n", Lambdas[i]);
fclose(ff);

	identifyPeaks_maxpeak(tar, Lambdas, thresholds, results, fplevels);

	printf("done.\n");fflush(stdout);
}

void estimateStds(vector<TARRAYRATIO> const &tar, int width, vector<double> &avgstds)
{
	//first, convert the ratios to standard normal
	avgstds.resize(width);
	int i, j, k, l, L = (int)tar.size();
	for(i = 0; i < width; i++)
	{	int rsz = min(L / 5, 100000);
		double xbar, mean, std;
		mean = std = 0;
		for(j = 0; j < rsz; j++)
		{	do {	k = (int)gsl_ran_flat(gammar, 0, (double)L - i);
			} while(!_validInterval(tar, k, i));
			xbar = 0;
			for(l = k; l < k + i + 1; l++)
				xbar += tar[l].ratio;
			xbar /= (double)(i + 1);
			mean += xbar;
			std += xbar * xbar;
		}
		mean /= (double)rsz;
		std = sqrt(std / (double)(rsz - 1) - mean * mean);
		avgstds[i] = std;
	}
	
	//rescale correlations
	double scaler = 1. / avgstds[0];//_scaler(tar, avgstds[0], 0.1, 0.9);
	for(i = 0; i < width; i++)
		avgstds[i] *= scaler;
}

//assuming symmetry and constant diagnals
//range is the size of variables considerred, neighbor is the range where cov is non-zero
void estimateCov(vector<TARRAYRATIO> const &tar, int range, int neighbor, vector<vector<double> > &cov, vector<vector<double> > &cl, double &mean, double &determinant)
{
	cov.clear();
	cov.resize(range, vector<double>(range, 0));
	if(neighbor < 0 || neighbor > range) neighbor = range;
	
	int i, j, k, l, L = (int)tar.size();	//nnnnnnnnnnnnnnnnnnnn, assume variance 1
	double vlow, vup, mn = 0, sigma;
	for(i = 0; i < L; i++)
		mn += tar[i].ratio;
	mn /= (double)L;
	sigma = _scaler(tar, 1., lowerquantile, upperquantile);
	vlow = mn + sigma * gsl_cdf_gaussian_Pinv(0.1 / (double)L, 1.);
	vup = mn + sigma * gsl_cdf_gaussian_Qinv(0.1 / (double)L, 1.);
//	getQuantileRange(tar, lowquantile, upquantile, vlow, vup);

//	vector<double> mm(range, 0);
	double m = 0;
	vector<double> ss(range, 0);
	int cnm = 0;
	vector<int> cns(range, 0), cnmm(range, 0);

	int rn = min(50000, L / 20);
	for(i = 0; i < rn; i++)
	{	do { j = (int)gsl_ran_flat(gammar, 0, (double)(L - range));
		} while(false);//!_validInterval(tar, j, range - 1));
		for(k = 0; k < range; k++)
		{	if(!_validInterval(tar, j, k)) break;
			if(tar[j + k].ratio > vup || tar[j + k].ratio < vlow) break; //nnnnnnnnnnnnnnnnnnnnn

			for(l = 0; l <= k; l++)
			{	//cov[k][l] += tar[j + k].ratio * tar[j + l].ratio;
				ss[k - l] += tar[j + k].ratio * tar[j + l].ratio;
				cns[k - l]++;
			}
//			mm[k] += tar[j + k].ratio;
//			cnmm[k]++;
			m += tar[j + k].ratio;
			cnm++;
		}
	}
	if(cnm > 0) m /= (double)cnm;//rn * range;
	for(k = 0; k < range; k++)
	{	//mm[k] /= (double)cnmm[k];
		if(cns[k] > 1) ss[k] /= (double)(cns[k] - 1);//rn * (range - k);
	}
	for(k = 0; k < range; k++)
	{	for(l = 0; l <= k; l++)
		{	cov[k][l] = ss[k - l] - /*mm[k] * mm[l];*/m * m;//mm[k] * mm[l];
						//cov[k][l] / (double)(rn - 1) - mm[k] * mm[l];
			if(fabs(cov[k][l]) < 0.02 * cov[0][0]) cov[k][l] = 0;
			if(k - l > neighbor) cov[k][l] = 0;
			cov[l][k] = cov[k][l];
		}
	}
	//rescale correlations
	double scaler = 1./sqrt(cov[0][0]);//_scaler(tar, sqrt(cov[0][0]), 0.1, 0.9);
	for(i = 0; i < (int)cov.size(); i++)
		for(j = 0; j < (int)cov[i].size(); j++)
		{	cov[i][j] *= scaler * scaler;
		}
	_choleskyDecomp(cov, cl, determinant);
	mean = m;

	FILE *f = fopen("cov.txt", "w");
	for(k = 0; k < range; k++)
	{	for(l = 0; l < range; l++)
			fprintf(f, "%5.4f\t", cov[k][l]);
		fprintf(f, "\n");
	}
	fprintf(f, "\n");
	for(i = 0; i < range; i++)
	{	for(j = 0; j < range; j++)
			fprintf(f, "%5.4f\t", cl[i][j]);
		fprintf(f, "\n");
	}
	fprintf(f, "\n%f\t%f\n", mean, determinant);

	fclose(f);

}
/*{
	cov.clear();
	cov.resize(range, vector<double>(range, 0));
	if(neighbor < 0 || neighbor > range) neighbor = range;

//	vector<double> mm(range, 0);
	double m = 0;
	vector<double> ss(range, 0);
	int cnm = 0;
	vector<int> cns(range, 0), cnmm(range, 0);
	int i, j, k, l, L = (int)tar.size();
	int rn = min(50000, L / 10);
	for(i = 0; i < rn; i++)
	{	do { j = (int)gsl_ran_flat(gammar, 0, (double)(L - range));
		} while(false);//!_validInterval(tar, j, range - 1));
		for(k = 0; k < range; k++)
		{	if(!_validInterval(tar, j, k)) break;
			for(l = 0; l <= k; l++)
			{	//cov[k][l] += tar[j + k].ratio * tar[j + l].ratio;
				ss[k - l] += tar[j + k].ratio * tar[j + l].ratio;
				cns[k - l]++;
			}
//			mm[k] += tar[j + k].ratio;
//			cnmm[k]++;
			m += tar[j + k].ratio;
			cnm++;
		}
	}
	m /= (double)cnm;//rn * range;
	for(k = 0; k < range; k++)
	{	//mm[k] /= (double)cnmm[k];
		ss[k] /= (double)(cns[k] - 1);//rn * (range - k);
	}
	for(k = 0; k < range; k++)
	{	for(l = 0; l <= k; l++)
		{	cov[k][l] = ss[k - l] - m * m;//mm[k] * mm[l];
						//cov[k][l] / (double)(rn - 1) - mm[k] * mm[l];
			if(fabs(cov[k][l]) < 0.02 * cov[0][0]) cov[k][l] = 0;
			if(k - l > neighbor) cov[k][l] = 0;
			cov[l][k] = cov[k][l];
		}
	}
	//rescale correlations
	double scaler = 1/sqrt(cov[0][0]);//_scaler(tar, sqrt(cov[0][0]), 0.1, 0.9);
	for(i = 0; i < (int)cov.size(); i++)
		for(j = 0; j < (int)cov[i].size(); j++)
			cov[i][j] *= scaler * scaler;

	_choleskyDecomp(cov, cl, determinant);
	mean = m;
}
*/

void _choleskyDecomp(vector<vector<double> > const &cov, vector<vector<double> > &cl, double &determinant)
{
	int sz = (int)cov.size();
	cl.clear();
	cl.resize(sz, vector<double>(sz, 0));
	int i, j, k;
	double a;
	determinant = 1.;
	for(i = 0; i < sz; i++)
	{	for(j = 0; j <= i; j++)
			if(cov[i][j] != 0)
			{	a = 0;
				for(k = 0; k < j; k++)
					a += cl[i][k] * cl[j][k];
				if(i == j) cl[i][j] = sqrt(max(0., cov[i][j] - a));
				else if(cl[j][j] != 0) cl[i][j] = (cov[i][j] - a) / (cl[j][j]);
				else cl[i][j] = 0;
			}
		determinant *= cl[i][i];
	}
	determinant *= determinant;
}

void identifyPeaks_joint_rank(vector<TARRAYRATIO> const &tar, vector<vector<double> > const &thresholds, vector<vector<double> > &result, vector<vector<double> > const &preavg)
{
	vector<vector<double> > averages;
	int width = (int)thresholds[0].size();
	if((int)preavg.size() > 0) averages = preavg;
	else getAverages(tar, 0, (int)tar.size(), width, averages);

	result.clear();
	int t, i, j, k;
	for(t = (int)thresholds.size() - 1; t >= 0; t--)
	{	for(i = 0; i < width; i++)
			for(j = 0; j < (int)averages[i].size(); j++)
			{	if(averages[i][j] >= thresholds[t][i] && _validInterval(tar, j, i))
				{	int presz = max(0, i - 1) + max(i - 1, PRESZ);
					for(k = j - 1; k >= max(0, j - presz); k--)
					{	if(averages[i][k] >= thresholds[t][i] && _validCover(tar, k, j))
							break;
					}
					if(k < max(0, j - presz))
					{	bool valid = true;
						int x;
						for(x = 0; x < i; x++)
						{	for(k = min(j + i + max(PRESZ, x) - x, (int)averages[x].size() - 1); k >= max(0, j - max(PRESZ, x)); k--)
							{	if(averages[x][k] >= thresholds[t][x])
								{	if((k > j && _validCover(tar, j, k)) || (k < j && _validCover(tar, k, j)))
									{	valid = false;
										break;
									}
								}
							}
							if(valid == false) break;
						}
						if(valid == true)
						{	vector<double> r;
							r.push_back(j);
							r.push_back(j + i);
							r.push_back(averages[i][j]);
							r.push_back((double)t);
							for(x = 0; x < (int)result.size(); x++)
							{	if(r[0] <= result[x][0] && r[1] + max(PRESZ, width - 1) >= result[x][0])
									break;
								if(r[0] >= result[x][0] && r[0] <= result[x][1] + max(PRESZ, width - 1))
									break;
							}
							if(x >= (int)result.size())
								result.push_back(r);
						}
					}
					j += i;
				}
			}
	}
}

void getAverages(vector<TARRAYRATIO> const &tar, int st, int ed, int avgSz, vector<vector<double> > &averages)
{
	int i, j;
	
	averages.clear();
	averages.resize(avgSz);
	for(i = 0; i < avgSz; i++)
	{	averages[i].resize(ed - st - i, 0);
		for(j = 0; j < ed - st - i; j++)
		{	if(i == 0) averages[i][j] = tar[st + j].ratio;
			else averages[i][j] = averages[i - 1][j] + tar[st + j + i].ratio;
		}
	}
	for(i = 1; i < avgSz; i++)
		for(j = 0; j < (int)averages[i].size(); j++)
			averages[i][j] /= (double)(i + 1);
}

void loadRatioData(char *filename, vector<TARRAYRATIO> &tar)
{
	tar.clear();
	FILE *f = fopen(filename, "r");
	if(f != NULL)
	{	int i, j;
		char tmp[2000];
		while(fgets(tmp, 2000, f) != NULL)
		{	if((int)strlen(tmp) < 5 || tmp[0] == '#') continue;
			TARRAYRATIO t;
			//read chr number
			i = 0;
			if(tmp[i + 3] >= 48 && tmp[i + 3] < 58) t.chr = atoi(&tmp[i + 3]);
			else if(tmp[i + 3] == 'X' || tmp[i + 3] == 'x') t.chr = 23;
			else if(tmp[i + 3] == 'Y' || tmp[i + 3] == 'y') t.chr = 24;
			else t.chr = -1;
			//read position
			j = 0;
			for(i = i + 3; i < (int)strlen(tmp); i++)
			{	if(tmp[i] == '\t' || tmp[i] == ' ') j++;
				if(j == 3) break;
			}
			t.pos = atoi(&tmp[i + 1]);
			//read ratio
			for(i = i + 1; i < (int)strlen(tmp); i++)
			{	if(tmp[i] == '\t' || tmp[i] == ' ') j++;
				if(j == 5) break;
			}
			t.ratio = atof(&tmp[i + 1]);
//if((int)tar.size() % 10000 == 0) printf("%f ", t.ratio),fflush(stdout);
			tar.push_back(t);
		}
		fclose(f);
		sort(tar.begin(), tar.end());
	}
}

void normalizeData_withOutliers(vector<TARRAYRATIO> &tar, bool localmean)
{ 	int L = (int)tar.size();
	int i, j;
	double mu = 0, sigma = 0;
	vector<double> data(L);

	if(localmean) localCorrection(tar);

	for(i = 0; i < L; i++)
	{	data[i] = tar[i].ratio;
		sigma += data[i] * data[i];
	}
	sort(data.begin(), data.end());
	//mu = data[L / 2];
	j = 0;
	for(i = (int)((double)L * lowerquantile + 1); i < (int)((double)L * upperquantile); i++)
	{	mu += data[i];
		j++;
	}
	mu /= (double)j;
	sigma = sqrt(sigma / (double)L - mu * mu);

	data.clear();
	double scaler = _scaler(tar, 1., lowerquantile, upperquantile);
printf("mean=%f\tstd=%f(%f)\n", mu, scaler, sigma);
	sigma = scaler;//sigma *= scaler;
	for(i = 0; i < L; i++)
		tar[i].ratio = (tar[i].ratio - mu) / sigma;
}
/*{	
	int L = (int)tar.size();
	int i;
	double mu, sigma = 0;
	vector<double> data(L);
	for(i = 0; i < L; i++)
	{	data[i] = tar[i].ratio;
		sigma += data[i] * data[i];
	}
	sort(data.begin(), data.end());
	mu = data[L / 2];
	sigma = sqrt(sigma / (double)L - mu * mu);
printf("mu = %f\tsigma = %f\t", mu, sigma);
	data.clear();
	double scaler = _scaler(tar, sigma, 0.1, 0.9);
	sigma *= scaler;
printf("adj_sigma = %f\n", sigma);
	for(i = 0; i < L; i++)
		tar[i].ratio = (tar[i].ratio - mu) / sigma;
}
*/

void localCorrection(vector<TARRAYRATIO> &tar)
{	int i, j, L = (int)tar.size();
        double mmm = 0, mm = 0, vv = 0, ml = 0, mr = 0, sss = 0;
        for(i = 0; i < L; i++)
        {       mmm += tar[i].ratio;
                sss += tar[i].ratio * tar[i].ratio;
        }
        mmm /= (double)L;
        sss = sqrt(sss / (double)L - mmm * mmm);
        vector<TARRAYRATIO> tmpt = tar;
	vector<MYTYPE> local;
        int sz = 0, ww = 500, w = 5;
        for(i = 0; i < L; i++)
        {       if(i == 0)
                {       for(j = 0; j <= min(L - 1, ww); j++)
                        {       if(fabs(tmpt[j].ratio - mmm) < sss) 
                                {       mm += tmpt[j].ratio;
                                        vv += tmpt[j].ratio * tmpt[j].ratio;
                                        sz ++;
                                }
				MYTYPE mt;
				mt.index = j;
				mt.ratio = tmpt[j].ratio;
				local.push_back(mt);
			}
			sort(local.begin(), local.end());

                        ml = mmm;
                        for(j = 1; j <= min(L - 1, w); j++)
                                mr += tmpt[j].ratio;
                }
mm = vv = 0;
int k = 0;
for(j = (int)local.size() / 10; j < (int)local.size() * 9 / 10; j++)
{	mm += local[j].ratio;
	vv += local[j].ratio * local[j].ratio;
	k++;
}
if(k > 0)
{ mm = mm / (double)k; vv = sqrt(vv / k - mm * mm); }
mm = local[(int)local.size() / 2].ratio;

                tar[i].ratio = (tar[i].ratio - mm) / vv;//sqrt(vv / (double)sz - mm / (double)sz * mm / (double)sz);
                if(i - ww >= 0 && fabs(tmpt[i - ww].ratio - mmm) < sss) 
                {       mm -= tmpt[i - ww].ratio; vv -= tmpt[i - ww].ratio * tmpt[i - ww].ratio; sz--; 
			for(j = 0; j < (int)local.size(); j++) 
			{	if(local[j].index == i - ww) 
				{	local.erase(local.begin() + j);
					break;
				}
			}
		}
                if(i + ww < L - 1 && fabs(tmpt[i + ww + 1].ratio - mmm) < sss) 
                {       mm += tmpt[i + ww + 1].ratio; vv += tmpt[i + ww + 1].ratio * tmpt[i + ww + 1].ratio; sz++; 
			for(j = 0; j < (int)local.size(); j++)
				if(tmpt[i + ww + 1].ratio < local[j].ratio) break;
			MYTYPE mt;
			mt.index = i + ww + 1;
			mt.ratio = tmpt[i + ww + 1].ratio;
			if(j < (int)local.size()) local.insert(local.begin() + j, mt);
			else local.push_back(mt);
		}
        //      if(fabs(tmpt[i].ratio - ml / (double)w) > 1.2*sss && fabs(tmpt[i].ratio - mr / (double)w) > 1.2*sss)  tar[i].ratio = 0;
                if(i - w >= 0) ml -= tmpt[i - w].ratio; 
                ml += tmpt[i].ratio;
                mr -= tmpt[i].ratio;
                if(i + w < L - 1) mr += tmpt[i + w + 1].ratio;
        }
}

void _lm(vector<double> const &x, vector<double> const &y, double &alpha, double &beta)
{	int i;
	int sz = (int)x.size();
	double xy, x2, xbar, ybar;
	xy = x2 = xbar = ybar = 0;
	for(i = 0; i < sz; i++)
	{	xy += x[i] * y[i];
		x2 += x[i] * x[i];
		xbar += x[i];
		ybar += y[i];
	}
	beta = (xy - xbar * (ybar / (double)sz)) / (x2 - xbar * (xbar / (double)sz));
	alpha = ybar / (double)sz - beta * (xbar / (double)sz);
}
/*
void _wlm(vector<double> const &x, vector<double> const &y, int id, double span, double &alpha, double &beta)
{	int i;
	int sz = (int)(span / 2. * (double)x.size() + 0.5) + 1;
	int st = max(0, id - sz);
	int ed = min((int)x.size(), id + sz + 1);
	if(ed - st < 3) 
	{	alpha = y[id];
		beta = 0;
		return;
	}
	vector<double> w(ed - st, 0);
	double maxd = x[ed - 1] - x[id];
	if(maxd < x[id] - x[st]) maxd = x[id] - x[st];
	for(i = st; i < ed; i++)
		w[i - st] = pow(1 - pow(fabs(x[id] - x[i]) / maxd, 3.), 3.);
	double sumw = 0;
	for(i = 0; i < ed - st; i++)
		sumw += w[i];

	double xy, x2, xbar, ybar;
	xy = x2 = xbar = ybar = 0;
	for(i = st; i < ed; i++)
	{	xy += x[i] * y[i] * w[i - st];
		x2 += x[i] * x[i] * w[i - st];
		xbar += x[i] * w[i - st];
		ybar += y[i] * w[i - st];
	}
	beta = (xy - xbar * (ybar / sumw)) / (x2 - xbar * (xbar / sumw) + 0.000001);
	alpha = (ybar - beta * xbar) / (sumw + 0.000001);
}

double _loess(vector<double> const &x, vector<double> const &y, double xstar, double span, bool incorder)
{	int i;
	double alpha, beta;

	double xmax = x[0], xmin = x[0], ymax = y[0], ymin = y[0];
	for(i = 0; i < (int)x.size(); i++)
	{	if(xmax < x[i]) xmax = x[i];
		if(xmin > x[i]) xmin = x[i];
		if(ymax < y[i]) ymax = y[i];
		if(ymin > y[i]) ymin = y[i];
	}

	if(xstar < xmin) return (ymax + 0.001);
	else if(xstar > xmax) return (ymin - 0.001);
	else
	{	vector<double> nx = x, ny = y;
		if(!incorder)
		{	vector<MYTYPE> order((int)x.size());
			for(i = 0; i < (int)x.size(); i++)
			{	order[i].ratio = x[i];
				order[i].index = i;
			}
			sort(order.begin(), order.end());
			for(i = 0; i < (int)x.size(); i++)
			{	nx[i] = x[order[i].index];
				ny[i] = y[order[i].index];
			}
		}
		for(i = 0; i < (int)nx.size(); i++)
			if(nx[i] <= xstar && nx[i + 1] >= xstar) 
				break;
		double rt;
		_wlm(nx, ny, i, span, alpha, beta);
		rt = alpha + beta * nx[i];
		if(nx[i] < xstar) 
		{	_wlm(nx, ny, i + 1, span, alpha, beta);
			rt = rt + (alpha + beta * nx[i + 1] - rt) * (xstar - nx[i]) / (nx[i + 1] - nx[i]);
		}
		return rt;
	}
}
*/
double _scaler(vector<TARRAYRATIO> const &tar, double stds, double pst, double ped)
{	int L = (int)tar.size();
	int	l = min(L, 1000000);
	vector<double> x(l), y(l);
	for(int i = 0; i < l; i++)
	{	x[i] = gsl_cdf_gaussian_Pinv((double)(i + 1) / (l + 1), stds);
		y[i] = tar[(int)((double)i / l * L)].ratio;
	}
	sort(x.begin(), x.end()); sort(y.begin(), y.end());
	x.resize((int)((double)l * ped)); y.resize((int)((double)l * ped));
	x.erase(x.begin(), x.begin() + (int)((double)l * pst)); y.erase(y.begin(), y.begin() + (int)((double)l * pst));
	double alpha, beta;
	_lm(x, y, alpha, beta);
	return beta;
}

void estimateThresholds_theoretical2(vector<TARRAYRATIO> const &tar, int wst, int width, vector<double> const &lambdas, vector<double> &thresholds, double mean, vector<vector<double> > &cov, vector<vector<double> > &cl, bool joint, int run)
{
	//esitmate maxmeans theoretically
	//first, estimate covariance matrix
	int i, j, l;
	double determinant;
	if((int)cov.size() == 0) estimateCov(tar, ((int)joint + 1) * max(width - 1, PRESZ) + width, -1, cov, cl, mean, determinant);
	vector<double> avgstds;
	estimateStds(tar, width, avgstds);

	//second, use importance sampling to determine theoretical means
	thresholds.clear();
	vector<double> tmpu;
	vector<int> ls, cs;
	if(wst > 1)
	{	thresholds.resize(wst - 1, 1000);
		if(joint) tmpu.resize(wst - 1, 1000);
		ls.resize(wst - 1, 0);
		cs.resize(wst - 1, 0);
	}

	for(j = wst - 1; j < width; j++)
	{	printf("winsize=%d\tlambda_%d=%5.3f\t", j + 1, j + 1, lambdas[j]); fflush(stdout);

		if(lambdas[j] <= 0) 
		{	thresholds.push_back(1000000.);
			ls.push_back(0);
			cs.push_back(0);
			continue;
		}
		int presz = max(j, PRESZ);
		if(joint) presz = max(PRESZ, j);//max(PRESZ, max(0,j - 1) + max(PRESZ, j - 1)); /////////////////////////////////
		int sufsz = max(PRESZ, j);///////////////////////////
		vector<double> coverdist, sufdist;
		getCoverDist(tar, j + 1, coverdist, l);
		getSufDist(tar, j + 1, sufdist);
		if((int)coverdist.size() > 0) presz = (int)coverdist.size() - 1;
		sufsz = max(0, (int)sufdist.size() - 1);

		ls.push_back(l);

		int usz = 100;
		vector<double> us(usz), pvalues;
		double ust, ued;
		int rr = run / width * (j + 1);
	
		int count = 0, out = 0;
		double range = avgstds[j];
		double startu = gsl_cdf_gaussian_Qinv(lambdas[j] / (double)l, avgstds[j]) - 0.5 * range + mean;
		if((int)tmpu.size() > 0 && *(tmpu.end() - 1) < startu) 
			startu = *(tmpu.end() - 1) - avgstds[j] / 4.;
		double u = startu;

bool a_inner;
		FILE *ff = fopen("pvalues.txt", "w"); fclose(ff);
		do {	double ou = u;
			ust = max(0.1, u - range / 2.);
			ued = max(ust, u + range / 2.);
			for(i = 0; i < usz; i++) 
				us[i] = ust + (double)i * range / (double)usz;
			vector<vector<double> > lowerT, tmpP;
			if((int)tmpu.size() > 0) lowerT.push_back(tmpu);
			estimateP_maxpeak(us, j + 1, cov, cl, rr, coverdist, sufdist, lowerT, tmpP);
			pvalues = tmpP[0];

			double alpha, beta;
			for(i = 0; i < (int)pvalues.size(); i++) 
				pvalues[i] = log(pvalues[i] * (double)l + 0.0000001);
			//_lm(pvalues, us, alpha, beta);	
			//u = log(lambdas[j]) * beta + alpha;
			u = _loess(pvalues, us, log(lambdas[j]));
			printf("(%5.3f~%5.3f,%5.3f,%5.3f) ", ust, ued, u, avgstds[j]);fflush(stdout);
/*
if(u > -100. && u < 100.);
else
{FILE *f = fopen("tmp.txt", "w");
for(i = 0; i < (int)pvalues.size(); i++)
        fprintf(f, "%f\t%f\n", pvalues[i], us[i]);
fprintf(f, "%f\n", log(lambdas[j]));
fclose(f);
exit(0);
}*/
			if(u < minBound * 0.8)
			{	thresholds.resize(width, u);
				printf(" threshold is too small (%5.3f < %5.3f)\n", u, minBound);
				return;
			}

			if(u >= ust && u <= ued)
				range /= 2.;
			else 
			{	out++;
				if(u < ust) u = ust;
	                        else if(u > ued) u = ued;
			}
			if(out > 4) 
			{	range *= 2.; out = 0; }
			if(range > avgstds[j]) range = avgstds[j];
//printf("lambda=%f\tu=%f\tstartu=%f\tavgstds=%f\n", lambdas[j], u, startu, avgstds[j]); fflush(stdout);
			count++;
			FILE *f = fopen("pvalues.txt", "a");
			for(i = 0; i < usz; i++) fprintf(f, "%f ", pvalues[i]);
			fprintf(f, "%f %f %f\n", ust, ued, u);
			fclose(f);
a_inner = false;
double p1 = exp(*(pvalues.end()-1));
double p2 = exp(pvalues[0]);
//printf("%f, %f, %f\n", p1, p2, lambdas[j]);
//if(fabs(p1-p2) > sqrt(lambdas[j]) / 2. || p2 < lambdas[j] || p1 > lambdas[j]) a_inner = true;
if(range >= avgstds[j]/16.) a_inner=true;
		} while(a_inner);//while(range >= avgstds[j] / 16.);
		thresholds.push_back(u);
		if(joint) tmpu.push_back(u);
		cs.push_back(count);
		
		FILE *f = fopen("thresholds.txt", "a");
		fprintf(f, "b%d\tu= %f\tl=%d\tlambda= %f\tc=%d\tmean=%f\trange= %f\n", j+1, thresholds[j], ls[j], lambdas[j], cs[j], mean, range);
		fclose(f);
		printf("\n");fflush(stdout);
	}
}


void _inverseLowerTriangularMatrix(vector<vector<double> > const &cl, vector<vector<double> > &il)
{	int i, j, k;
	int sz = (int)cl.size();
	il.clear();
	il.resize(sz, vector<double>(sz, 0));
	
	for(i = 0; i < sz; i++)
	{	if(cl[i][i] == 0) il[i][i] = 0;
		else il[i][i] = 1. / cl[i][i];
	}
	for(k = 1; k < sz; k++)
		for(i = k; i < sz; i++)
		{	double sum = 0;
			for(j = i - k; j < i; j++)
				sum += cl[i][j] * il[j][i - k];
			if(cl[i][i] == 0) il[i][i - k] = 0;
			else il[i][i - k] = - sum / cl[i][i];
		}
}

void getCoverDist(vector<TARRAYRATIO> const &tar, int width, vector<double> &coverdist, int &l)
{	
	int j, k;
	int presz = PRESZ + width - 1;
	coverdist.clear();
	coverdist.resize(presz + 1, 0);
	l = 0;
	for(j = 0; j < (int)tar.size() - width + 1; j++)
		if(_validInterval(tar, j, width - 1)) 
		{	l++;
			for(k = j - 1; k >= max(0, j - presz); k--)
				if(!_validInterval(tar, k, width - 1) || !_validCover(tar, k, j))	break;	
			coverdist[presz - (j - 1 - k)]++;
		}
	for(k = 1; k < (int)coverdist.size(); k++)
		coverdist[k] += coverdist[k - 1];
	for(k = 0; k < (int)coverdist.size(); k++)
		coverdist[k] /= *(coverdist.end() - 1);	
}

void getSufDist(vector<TARRAYRATIO> const &tar, int width, vector<double> &sufdist)
{	
	int	j, k;
	int sufsz = PRESZ + width - 1; /////////////////////
	sufdist.clear();
	sufdist.resize(sufsz + 1, 0);
	for(j = 0; j < (int)tar.size() - width + 1; j++)
		if(_validInterval(tar, j, width - 1)) 
		{	for(k = j + 1; k < min((int)tar.size() - width + 1, j + 1 + sufsz); k++)
				if(!_validInterval(tar, k, max(0, width - 2)) || !_validCover(tar, j, k))	break;	
			sufdist[k - (j + 1)]++;
		}
	for(k = 1; k < (int)sufdist.size(); k++)
		sufdist[k] += sufdist[k - 1];
	for(k = 0; k < (int)sufdist.size(); k++)
		sufdist[k] /= *(sufdist.end() - 1);	
}

void resizeCov(vector<vector<double> > const &orgcov, int nsz, vector<vector<double> > &cov)
{	int osz = (int)orgcov.size();
	cov.clear();
	cov.resize(nsz, vector<double>(nsz, 0));
	int i, j;
	for(i = 0; i < min(osz, nsz); i++)
	{	for(j = 0; j < nsz - i; j++)
			cov[i + j][j] = cov[j][i + j] = orgcov[i][0]; 
	}
}

void estimateThresholds_theoretical_joint(vector<TARRAYRATIO> const &tar, int wst, int wed, double minlambdaJ, double maxlambdaJ, int sz,
				vector<double> &lambdas, vector<vector<double> > &thresholds, double &mean, vector<vector<double> > &cov, vector<vector<double> > &cl, int run)
{	
	int i, j, k;
	//esitmate maxmeans theoretically
	//first, determine a proper range to work with
	vector<double> minu, maxu;
	vector<double> tmplambdas(wed, 0);
	for(i = wst - 1; i < wed; i++)
	{	tmplambdas[i] = maxlambdaJ / (double)(wed - wst + 1);	}
	estimateThresholds_theoretical2(tar, wst, wed, tmplambdas, maxu, mean, cov, cl, true, run);
	for(i = wst - 1; i < wed; i++)
	{	tmplambdas[i] = minlambdaJ / (double)(wed - wst + 1);	}
	estimateThresholds_theoretical2(tar, wst, wed, tmplambdas, minu, mean, cov, cl, true, run);

	vector<double> morelambdas(sz * 1);
	lambdas.resize(sz);
	for(i = 0; i < sz; i++)
		lambdas[i] = exp(log(maxlambdaJ / (double)(wed - wst + 1)) - (double)i * log(maxlambdaJ / minlambdaJ) / (double)(sz - 1));
	for(i = 0; i < (int)morelambdas.size(); i++)
		morelambdas[i] = exp(log(maxlambdaJ / (double)(wed - wst + 1)) - (double)i * log(maxlambdaJ / minlambdaJ) / ((double)morelambdas.size() - 1.));
		
	//second, use importance sampling to determine theoretical means
	vector<vector<double> > us;
	for(i = 0; i < wed; i++)
	{	if(i < wst - 1)
		{	if((int)us.size() == 0) us.resize(sz, vector<double>(1, 1000000.));
			else 
			{	for(j = 0; j < (int)us.size(); j++)
					us[j].push_back(1000000.);
			}
		}
		else
		{	int presz = max(i, PRESZ);
			int l;
			vector<double> coverdist, sufdist;
			getCoverDist(tar, i + 1, coverdist, l);
			getSufDist(tar, i + 1, sufdist);
			if((int)coverdist.size() > 0) presz = (int)coverdist.size() - 1;
			int sufsz = max(0, (int)sufdist.size() - 1);

			vector<vector<double> > tcov, tcl;
			resizeCov(cov, presz + i + 1 + sufsz, tcov);
			//switch columns & rows
			{	int x, pos = presz + (i + 1) / 2;
				double tmp;
				for(x = 0; x < (int)tcov.size(); x++)
				{	tmp = tcov[0][x]; tcov[0][x] = tcov[pos][x]; tcov[pos][x] = tmp;	}
				for(x = 0; x < (int)tcov.size(); x++)
				{	tmp = tcov[x][0]; tcov[x][0] = tcov[x][pos]; tcov[x][pos] = tmp;	}
			}
			double determinant;
			_choleskyDecomp(tcov, tcl, determinant);

			vector<double> u((int)morelambdas.size()); //check more points
			vector<vector<double> > estn;
			for(j = 0; j < (int)u.size(); j++)
				u[j] = maxu[i] + (minu[i] - maxu[i]) * log(morelambdas[j] / morelambdas[0]) / log(morelambdas[sz - 1] / morelambdas[0]);
		//	estimateP_IS_joint(u, i + 1, mean, cl, estn, coverdist, us, sufdist, run);
			printf("Joint winsize = %d, lambda_%d = %5.3f~%5.3f\n", i + 1, i + 1, minlambdaJ / (double)(wed - wst + 1), maxlambdaJ / (double)(wed - wst + 1)); fflush(stdout);
			estimateP_maxpeak(u, i + 1, cov, cl, run, coverdist, sufdist, us, estn);
		//	estimateP_IS_jointnew(u, i + 1, mean, tcl, estn, coverdist, us, sufdist, run);

			if((int)us.size() == 0)
			{	us.resize(sz);
				estn.resize(sz);
				for(j = 1; j < sz; j++)
					estn[j] = estn[0];
			}
			for(j = 0; j < sz; j++)
			{	for(k = 0; k < (int)estn[j].size(); k++)
					if(estn[j][k] * (double)l <= lambdas[j])
						break;
				if(k >= (int)estn[j].size())
					us[j].push_back(*(u.end() - 1));
				else if(k == 0) us[j].push_back(*(u.begin()));
				else us[j].push_back(u[k - 1] + log(estn[j][k - 1] * l / lambdas[j]) / log(estn[j][k - 1]/estn[j][k]) * (u[k] - u[k - 1]));
			}
			
		}
	}
	thresholds = us;

	FILE *f = fopen("thresholds_all.txt", "w");
	for(i = 0; i < sz; i++)
	{	fprintf(f, "%f:\t", lambdas[i]);
		for(j = 0; j < wed; j++)
			fprintf(f, "%f\t", us[i][j]);
		fprintf(f, "\n");
	}
	fclose(f);
}

void estimateP_IS_joint(vector<double> const &u, int width, double mean, vector<vector<double> > const &cl,
		  vector<vector<double> > &pvalues, vector<double> const &coverdist, vector<vector<double> > const &us, vector<double> const &sufdist, int run)
{	
	int n = run;
	int i, j, k, l, m;
	int presz = max(PRESZ, width - 1);
	if((int)coverdist.size() > 0) presz = (int)coverdist.size() - 1;
	int sufsz = max(0, (int)sufdist.size() - 1);

	vector<vector<double> > il;
	_inverseLowerTriangularMatrix(cl, il);

	pvalues.clear();
	pvalues.resize(max(1, (int)us.size()), vector<double>((int)u.size(), 0));
	if(PRESZ + width <= 1) 
	{	for(i = 0; i < (int)u.size(); i++)
			pvalues[0][i] = gsl_cdf_gaussian_Q(u[i] - mean, 1);
		return;
	}

	vector<double> ds(presz + width + sufsz, mean), rds((int)ds.size(), 0);
	double rho = 0;
	for(j = 0; j < (int)ds.size(); j++)
	{	double cc = 0;
		rho = 0;
		for(k = - width + 1; k <= width - 1; k++)
		{	rho += cl[abs(presz + width / 2 - j + k)][0] * (double)(width - abs(k));
			cc += cl[abs(k)][0] * (double)(width - abs(k));
		}
		ds[j] += (*u.begin() + *(u.end()-1) * 20.) / 21. * rho / (cc + 0.0000000001);//exp(- (double)abs(presz + width / 2 - j) / presz * 2.);
	}
	for(j = 0; j < (int)ds.size(); j++)
	{	for(k = 0; k <= j; k++)
		{	rds[j] += ds[k] * il[j][k]; //assume xs is column vector and cl is lower triangle, then either xs'*cl' or cl*xs
		}
	}

	for(i = 0; i < n; i++)
	{	vector<double> avgs(presz + 1 + sufsz, 0);
		vector<double> xs(presz + width + sufsz);
		double scaler = gsl_ran_gaussian(gammar, 0.1) + 1.;
		for(j = 0; j < (int)xs.size(); j++)
		{	xs[j] = gsl_ran_gaussian(gammar, 1);// + ds[j];
		}
		vector<double> cxs((int)xs.size(), 0);
		for(j = 0; j < (int)ds.size(); j++)
			cxs[j] = ds[j] * scaler;
		for(j = 0; j < (int)xs.size(); j++)
		{	for(k = 0; k < (int)xs.size(); k++)
				cxs[j] += xs[k] * cl[j][k];
		}
		for(j = 0; j < (int)xs.size(); j++)
			for(k = max(0, j - width + 1); k <= min((int)avgs.size() - 1, j); k++)
				avgs[k] += cxs[j];

		int b = 0;
		if((int)coverdist.size() > 0)
		{	double un = gsl_ran_flat(gammar, 0, *(coverdist.end() - 1));
			for(b = 0; b < (int)coverdist.size(); b++)
				if(un <= coverdist[b])
					break;
		}

		double xmax = -1000, xx = avgs[presz] / (double)width;
		for(j = b; j < presz; j++)
			xmax = max(xmax, avgs[j] / (double)width);
		if(xmax < xx) 
		{	int s = 0;
			if((int)sufdist.size() > 0)
			{	double un = gsl_ran_flat(gammar, 0, *(sufdist.end() - 1));
				for(s = 0; s < (int)sufdist.size(); s++)
					if(un <= sufdist[s])
						break;
			}
			vector<double> maxavg(width - 1, -10000000);
			for(j = 0; j < width - 1; j++)
			{	int ppsz = max(PRESZ, j);////////////////////////////////
				int sssz = max(PRESZ, j);/////////////////////
				vector<double> tmpavg(width - j + min(sssz, s) + ppsz, 0); //////////////////////
				int c = presz - ppsz;
				int d = max(b - c, 0);
				for(k = c; k < presz + width + sssz; k++) //////////////////////
					for(l = max(d, k - c - j); l <= min((int)tmpavg.size() - 1, k - c); l++)
						tmpavg[l] += cxs[k];
				for(k = 0; k < (int)tmpavg.size(); k++)
					if(maxavg[j] < tmpavg[k])
						maxavg[j] = tmpavg[k];
				maxavg[j] /= (double)(j + 1);
			}

			bool flag = false;
			vector<bool> selected(max(1, (int)us.size()), false);
			for(j = 0; j < (int)us.size(); j++)
			{	for(l = 0; l < width - 1; l++)
				{	if(maxavg[l] >= us[j][l])
						break;	
				}
				if(l >= width - 1) 
				{	selected[j] = true; flag = true;	}
			}
			if((int)us.size() == 0) 
			{	selected[0] = true;
				flag = true;
			}

			if(flag)
			{	double delta = 0;
				for(k = 0; k < (int)xs.size(); k++)
					delta += (- (xs[k] + rds[k] * scaler) * (xs[k] + rds[k] * scaler) / 2. + (xs[k]) * (xs[k]) / 2.);
				delta = exp(delta);
				
				for(j = 0; j < (int)selected.size(); j++)
					if(selected[j])
					{	for(k = 0; k < (int)u.size(); k++)
							if(xmax < u[k]) break;
						for(l = k; l < (int)u.size(); l++)
							if(xx < u[l]) break;
						for(m = k; m < l; m++)
							pvalues[j][m] += delta;
					}
			}
		}
	}

	for(i = 0; i < (int)pvalues.size(); i++)
		for(j = 0; j < (int)pvalues[i].size(); j++)
			pvalues[i][j] /= (double)n;
}

void estimateP_IS_jointnew(vector<double> const &u, int width, double mean, vector<vector<double> > const &cl,
		  vector<vector<double> > &pvalues, vector<double> const &coverdist, vector<vector<double> > const &us, vector<double> const &sufdist, int run)
{	
	int n = run;
	int i, j, k, l, m;
	int presz = max(PRESZ, width - 1);
	if((int)coverdist.size() > 0) presz = (int)coverdist.size() - 1;
	int sufsz = max(0, (int)sufdist.size() - 1);

	vector<vector<double> > il;
	_inverseLowerTriangularMatrix(cl, il);

	pvalues.clear();
	pvalues.resize(max(1, (int)us.size()), vector<double>((int)u.size(), 0));
	if(PRESZ + width <= 1) 
	{	for(i = 0; i < (int)u.size(); i++)
			pvalues[0][i] = gsl_cdf_gaussian_Q(u[i] - mean, 1);
		return;
	}

	vector<double> ds(presz + width + sufsz, mean), rds((int)ds.size(), 0);
	rds[0] = (*u.begin() + *(u.end()-1) * 1.) / (1. + 1.);
	for(j = 0; j < (int)ds.size(); j++)
	{	ds[j] += rds[0] * cl[j][0]; //assume xs is column vector and cl is lower triangle, then either xs'*cl' or cl*xs
	}

	for(i = 0; i < n; i++)
	{	vector<double> avgs(presz + 1 + sufsz, 0);
		vector<double> xs(presz + width + sufsz);
		double scaler = gsl_ran_gaussian(gammar, 0.1) + 1.;
		for(j = 0; j < (int)xs.size(); j++)
		{	xs[j] = gsl_ran_gaussian(gammar, 1);// + ds[j];
		}
		vector<double> cxs((int)xs.size(), 0);
		for(j = 0; j < (int)ds.size(); j++)
			cxs[j] = ds[j] * scaler;
		for(j = 0; j < (int)xs.size(); j++)
		{	for(k = 0; k < (int)xs.size(); k++)
				cxs[j] += xs[k] * cl[j][k];
		}
		double tmp = cxs[0];
		cxs[0] = cxs[presz + width / 2];
		cxs[presz + width / 2] = tmp;

		for(j = 0; j < (int)xs.size(); j++)
			for(k = max(0, j - width + 1); k <= min((int)avgs.size() - 1, j); k++)
				avgs[k] += cxs[j];

		int b = 0;
		if((int)coverdist.size() > 0)
		{	double un = gsl_ran_flat(gammar, 0, *(coverdist.end() - 1));
			for(b = 0; b < (int)coverdist.size(); b++)
				if(un <= coverdist[b])
					break;
		}

		double xmax = -1000, xx = avgs[presz] / (double)width;
		for(j = b; j < presz; j++)
			xmax = max(xmax, avgs[j] / (double)width);
		if(xmax < xx) 
		{	int s = 0;
			if((int)sufdist.size() > 0)
			{	double un = gsl_ran_flat(gammar, 0, *(sufdist.end() - 1));
				for(s = 0; s < (int)sufdist.size(); s++)
					if(un <= sufdist[s])
						break;
			}
			vector<double> maxavg(width - 1, -10000000);
			for(j = 0; j < width - 1; j++)
			{	int ppsz = max(PRESZ, j);////////////////////////////////
				int sssz = max(PRESZ, j);/////////////////////
				vector<double> tmpavg(width - j + min(sssz, s) + ppsz, 0); //////////////////////
				int c = presz - ppsz;
				int d = max(b - c, 0);
				for(k = c; k < presz + width + sssz; k++) //////////////////////
					for(l = max(d, k - c - j); l <= min((int)tmpavg.size() - 1, k - c); l++)
						tmpavg[l] += cxs[k];
				for(k = 0; k < (int)tmpavg.size(); k++)
					if(maxavg[j] < tmpavg[k])
						maxavg[j] = tmpavg[k];
				maxavg[j] /= (double)(j + 1);
			}

			bool flag = false;
			vector<bool> selected(max(1, (int)us.size()), false);
			for(j = 0; j < (int)us.size(); j++)
			{	for(l = 0; l < width - 1; l++)
				{	if(maxavg[l] >= us[j][l])
						break;	
				}
				if(l >= width - 1) 
				{	selected[j] = true; flag = true;	}
			}
			if((int)us.size() == 0) 
			{	selected[0] = true;
				flag = true;
			}

			if(flag)
			{	double delta = 0;
				for(k = 0; k < (int)xs.size(); k++)
					delta += (- (xs[k] + rds[k] * scaler) * (xs[k] + rds[k] * scaler) / 2. + (xs[k]) * (xs[k]) / 2.);
				delta = exp(delta);
				
				for(j = 0; j < (int)selected.size(); j++)
					if(selected[j])
					{	for(k = 0; k < (int)u.size(); k++)
							if(xmax < u[k]) break;
						for(l = k; l < (int)u.size(); l++)
							if(xx < u[l]) break;
						for(m = k; m < l; m++)
							pvalues[j][m] += delta;
					}
			}
		}
	}

	for(i = 0; i < (int)pvalues.size(); i++)
		for(j = 0; j < (int)pvalues[i].size(); j++)
			pvalues[i][j] /= (double)n;
}

void quantileNormalization(vector<TARRAYRATIO> &tar)
{	int i, L = (int)tar.size();
	vector<MYTYPE> t(L);
	for(i = 0; i < L; i++)
	{	t[i].ratio = tar[i].ratio;
		t[i].index = i;
	}
	sort(t.begin(), t.end());
//	vector<double> d(L);
//	for(i = 0; i < L; i++) d[i] = gsl_ran_gaussian(gammar, 1.);
//	sort(d.begin(), d.end());
	for(i = 0; i < L; i++)
	{	//if(gsl_cdf_gaussian_P(t[i].ratio, 1) > 1. / (double)tar.size()
		//	&& gsl_cdf_gaussian_P(t[i].ratio, 1) < 1. - 1. / (double)tar.size())
		tar[t[i].index].ratio = /*d[i];/*/gsl_cdf_gaussian_Pinv((double)(i + 1) / (L + 1), 1);
	}
}






//us: ranges of thresholds
//width: window size for calculating statistics
//pvalues: p-values of threshold "us" given cutoffs of smaller windows in lowerT, each row correspond to each set (row) of cutoff in lowerT
//lowerT: cutoffs for smaller windows, may have multiple rows, or no rows 
//predist, sufdist: distribution of prefix sizes and sufix sizes relative to current position (so suffix include window size 
void estimateP_maxpeak(vector<double> const &us, int winwidth, vector<vector<double> > const &cov, vector<vector<double> > const &cl, int repn, 
					   vector<double> const &predist, vector<double> const &sufdist, vector<vector<double> > const &lowerT, vector<vector<double> > &pvalues)
{	
	int i, j, k;
	int halfwidth = PRESZ + winwidth - 1; //area to be checked for dependent peaks
	int presz = halfwidth; //area to simulate data
	int sufsz = presz;
	int allwidth = presz + winwidth + sufsz;

	//prepare importance sampling parameters
    	vector<double> sigma(allwidth, 1.0);
    	for(i = 0; i < allwidth; i++)
    	{       sigma[i] = 1.;// + 0*3.2 * fabs(cov[i][0]) / sqrt(cov[i][i] * cov[0][0]);//(double)i / asz * 1.6;
    	}

	double scale = 0;
	for(i = 0; i < winwidth; i++)
		scale = scale + cov[presz + winwidth / 2][presz + i];
	double add = (us[0] + *(us.end() - 1) * 2.) / (2. + 1.);
	add /= scale;
	vector<double> rs(allwidth, 0), rrs(allwidth, 0), ds(allwidth, 0);
	for(i = 0; i < winwidth; i++)
		rs[presz + i] = add;// * cov[presz + winwidth / 2][presz + i];
	for(i = 0; i < allwidth; i++)
		for(j = i; j < allwidth; j++) //assume cl is in lower triangle form
			rrs[i] += rs[j] * cl[j][i]; //rrs is the real contribution needed for independence component
	for(i = 0; i < winwidth; i++)
		for(j = 0; j < allwidth; j++)
			ds[j] += cov[presz + i][j] * add;

//start importance sampling
	pvalues.clear();
	if((int)lowerT.size() == 0) pvalues.resize(1, vector<double>((int)us.size(), 0));
	else pvalues.resize((int)lowerT.size(), vector<double>((int)us.size(), 0));
    	for(int r = 0; r < repn; r++)
	{   vector<double> norms(allwidth, 0), transnorms = ds;
	    for(i = 0; i < allwidth; i++)
			//if(cl[i][i] > clthreshold) 
				norms[i] = gsl_ran_gaussian(gammar, sigma[i]);
		
	    for(i = 0; i < allwidth; i++)
			for(j = 0; j <= i; j++)
				transnorms[i] += norms[j] * cl[i][j];

		vector<vector<double> > sums;
		getSums(transnorms, winwidth, sums);

		int st = 0, ed = allwidth;
		if((int)predist.size() > 0)
		{	double un = gsl_ran_flat(gammar, 0, *(predist.end() - 1));
			for(i = 0; i < (int)predist.size(); i++)
				if(un <= predist[i])
					break;
			st = max(0, presz - (int)predist.size() + i + 1);
		}
		if((int)sufdist.size() > 0)
		{	double un = gsl_ran_flat(gammar, sufdist[winwidth - 1], *(sufdist.end() - 1));
			for(i = 0; i < (int)sufdist.size(); i++)
				if(un <= sufdist[i])
					break;
			ed = min(allwidth, presz + i + 1);
			ed = max(presz + winwidth, ed);
		}

		double maxsum = 0;
		for(i = st; i < (int)sums[winwidth - 1].size() && i < ed - winwidth + 1; i++)
			if(i != presz && sums[winwidth - 1][i] > maxsum) 
				maxsum = sums[winwidth - 1][i];
		if(sums[winwidth - 1][presz] > maxsum)
		{	
			bool flag = false;
			vector<bool> selected(max(1, (int)lowerT.size()), false);
			if((int)lowerT.size() > 0 && winwidth > 1)
			{	vector<int> maxsumId(winwidth - 1, -1);
	                        for(j = 0; j < winwidth - 1; j++)
        	                {       for(k = max(st, presz - (PRESZ + j)); k < (int)sums[j].size() && k < min(ed - j, presz + winwidth + PRESZ + j); k++)
                	                        if(maxsumId[j] < 0 || sums[j][maxsumId[j]] < sums[j][k])
                        	                        maxsumId[j] = k;
                        	}
				for(j = 0; j < (int)lowerT.size(); j++)
				{	for(k = 0; k < winwidth - 1; k++)
					{	if(sums[k][maxsumId[k]] >= lowerT[j][k] * (double)(k + 1))
							break;	
					}
					if(k >= winwidth - 1) 
					{	selected[j] = true; flag = true;	}
				}
			}
			else
			{	selected[0] = true;
				flag = true;
			}

			if(flag)
			{	for(j = 0; j < (int)us.size(); j++)
					if(sums[winwidth - 1][presz] < us[j] * (double)winwidth)
						break;
				if(j > 0)
				{	double w = 0;
					for(i = 0; i < allwidth; i++)
					{	w += -pow(norms[i] + rrs[i], 2.) / 2. + pow(norms[i], 2.) / 2. / sigma[i] / sigma[i] + log(sigma[i]);        			
					}
					w = exp(w);
					for(i = 0; i < (int)selected.size(); i++)
						if(selected[i])
						{	for(k = 0; k < j; k++)
								pvalues[i][k] += w;
						}
				}
			}
		}
	}
	for(i = 0; i < (int)pvalues.size(); i++)
		for(j = 0; j < (int)pvalues[i].size(); j++)
			pvalues[i][j] /= (double)repn;
}

void getSums(vector<double> const &data, int maxWin, vector<vector<double> > &sums)
{
	int i, j;
	
	sums.clear();
	sums.resize(maxWin);
	sums[0] = data;
	for(i = 1; i < maxWin; i++)
	{	sums[i].resize((int)data.size() - i, 0);
		for(j = 0; j < (int)data.size() - i; j++)
			sums[i][j] = sums[i - 1][j] + data[j + i];
	}
}

void declumpPeak(vector<TARRAYRATIO> &tar, int pos, int winwidth, vector<double> &removevalue, int &st, int &ed)
{	
	int i, j;
	int midpoint = pos + (winwidth - 1) / 2;
	int halfwidth = (PRESZ + winwidth) * PROBEINTERV;

	vector<double> x, y;
	for(i = midpoint; i >= 0; i--)
	{	if(tar[i].chr != tar[midpoint].chr || tar[i].pos < tar[midpoint].pos - max(halfwidth * 2, 500)) break;
		x.push_back(tar[midpoint].pos - tar[i].pos);
		y.push_back(tar[i].ratio);
	}
	double a, b, p;
	vector<double> predict;

	for(i = 0; i < (int)x.size(); i++)
	{	_wlm(x, y, i, max(0.2, 12. / (double)x.size()), a, b);
		if(i >= (winwidth + PRESZ) / 2 && b > 0) break;
		p = a + x[i] * b;
//if(tar[pos].pos == 47488773) printf("l%d=%f, ", i, p),fflush(stdout);
		if(p > 0) predict.push_back(p);
		else 
		{	predict.push_back(0);
			if(tar[midpoint-i].chr != tar[midpoint].chr || tar[midpoint-i].pos < tar[midpoint].pos - 300) break; //revised 08/27/09
		}
	}
	if(p <= 0) x.resize(i); //revised 08/27/09

	if(i < (int)x.size() && p > 0)
	{	//predict.clear();
		vector<double> nx = x, ny = y;
		nx.resize(i);
		ny.resize(i);
		for(i = 0; i < (int)nx.size(); i++)
		{	_wlm(nx, ny, i, max(0.2, 12. / (double)x.size()), a, b);
			p = max(0., a + nx[i] * b);
			if((int)predict.size() > i) predict[i] = p;
			else predict.push_back(p);
		}
		if(p > 0 && b < 0) //revised 08/27/09
		{	for(i = midpoint - i; i >= 0; i--)
			{	if(tar[i].chr != tar[midpoint].chr || tar[i].pos < tar[midpoint].pos - max(halfwidth * 2, 500)) break;
				p = a + (tar[midpoint].pos - tar[i].pos) * b;
				if(p > 0) predict.push_back(p);
				else break;
			}
		}
	}
	st = midpoint - (int)predict.size() + 1;
	if((int)predict.size() > 1) reverse(predict.begin(), predict.end());
	
	x.clear(); y.clear();
	for(i = midpoint; i < (int)tar.size(); i++)
	{	if(tar[i].chr != tar[midpoint].chr || tar[i].pos > tar[midpoint].pos + max(halfwidth * 2, 500)) break;
		x.push_back(tar[i].pos - tar[midpoint].pos);
		y.push_back(tar[i].ratio);
	}
	vector<double> predict1;
	for(i = 0; i < (int)x.size(); i++)
	{	_wlm(x, y, i, max(0.2, 12. / (double)x.size()), a, b);
		if(i >= (winwidth + PRESZ) / 2 && b > 0) break;
		p = a + x[i] * b;
//if(tar[pos].pos == 47488773) printf("r%d=%f, ", i, p),fflush(stdout);

		if(p > 0) predict1.push_back(p);
		else 
		{	predict1.push_back(0);
			if(tar[midpoint+i].chr != tar[midpoint].chr || tar[midpoint+i].pos > tar[midpoint].pos + 300) break; //revised 08/27/09
		}
	}
	if(p <= 0) x.resize(i); //revised 08/27/09

	if(i < (int)x.size() && p > 0)
	{	//predict1.clear();
		vector<double> nx = x, ny = y;
		nx.resize(i);
		ny.resize(i);
		for(i = 0; i < (int)nx.size(); i++)
		{	_wlm(nx, ny, i, max(0.2, 12. / (double)x.size()), a, b);
			p = max(0., a + nx[i] * b);
			if((int)predict1.size() > i) predict1[i] = p;
			else predict1.push_back(p);
		}
		if(p > 0 && b < 0) //08/27/09
		{	for(i = midpoint + i; i < (int)tar.size(); i++)
			{	if(tar[i].chr != tar[midpoint].chr || tar[i].pos > tar[midpoint].pos + max(halfwidth * 2, 500)) break;
				p = a + (tar[i].pos - tar[midpoint].pos) * b;
				if(p > 0) predict1.push_back(p);
				else break;
			}
		}
	}
	ed = midpoint + (int)predict1.size();
	removevalue = predict;
	if((int)predict1.size() > 0) removevalue[(int)predict.size() - 1] = (removevalue[(int)predict.size() - 1] + predict1[0])/2.;
	if((int)predict1.size() > 1)
		removevalue.insert(removevalue.end(), predict1.begin() + 1, predict1.end());
	for(i = st; i < ed; i++) 
	{//	if(i >= pos & i < pos + winwidth) removevalue[i - st] = tar[i].ratio;
		tar[i].ratio -= removevalue[i - st];
	}
}

void identifyPeaks_maxpeak(vector<TARRAYRATIO> const &tar, vector<double> const &Lambdas, vector<vector<double> > const &thresholds, vector<vector<double> > &result, vector<double> const &fplevels, vector<vector<double> > const &preavg)
{
	int width = (int)thresholds[0].size();
	vector<vector<double> > averages;
	if((int)preavg.size() > 0) averages = preavg;
	else getAverages(tar, 0, (int)tar.size(), width, averages);
	vector<TARRAYRATIO> dtar = tar;	
	
	result.clear();
	int t, i, j, k;
	double upbound = 0;
	for(i = 0; i < (int)fplevels.size(); i++)
		upbound += fplevels[i];
	
	vector<int> lvs((int)tar.size(), -1);
	for(i = 0; i < (int)tar.size(); i++)
		lvs[i] = _getLevels(Lambdas, fplevels, upbound, i, (int)tar.size(), (int)thresholds.size() - 1);
	for(t = (int)thresholds.size() - 1; t >= 0; t--)
	{
	//	for(i = 0; i < (int)tar.size(); i++)
          //      	lvs[i] = _getLevels(Lambdas, fplevels, upbound, i, (int)tar.size(), t);

		if(Lambdas[t] > upbound) break;
		printf("\nt=%d, Lambdas[t]=%f:", t, Lambdas[t]);
	//	vector<int> lvs((int)tar.size(),t);
		for(i = 0; i < width; i++)
		{	for(j = 0; j < (int)averages[i].size(); j++)
			{	/////////////
			//	if(j % ((int)tar.size() / 10) == 0) printf("%d ", j);

				int lj = min(lvs[j + (i + 1) / 2], (int)thresholds.size() - 1);
				//if(lj < 0) lj = lvs[j] = _getLevels(Lambdas, fplevels, upbound, j+(i+1)/2, (int)tar.size(), t);
				if(averages[i][j] >= thresholds[lj][i] && _validInterval(tar, j, i))
				////////////////////////////
				//if(averages[i][j] >= thresholds[t][i] && _validInterval(tar, j, i) && ((int)fplevels.size() == 0 || fplevels[j + (i + 1)/2] * (double)tar.size() >= Lambdas[t]))
				{	
					for(k = min(j + PRESZ, (int)averages[i].size() - 1); k >= max(0, j - PRESZ - i); k--)
					{	////////////	
						int lk = min(lvs[k + (i + 1) / 2], (int)thresholds.size() - 1);
						//if(lk < 0) lk = lvs[k] = _getLevels(Lambdas, fplevels, upbound, k+(i+1)/2, (int)tar.size(), t);
						if(k != j && /*averages[i][k] >= thresholds[lk][i] && */averages[i][k] > averages[i][j])
						////////////
						//if(k != j && averages[i][k] >= averages[i][j])
						{	if((k > j && _validCover(tar, j, k)) || (k < j && _validCover(tar, k, j)))
								break;
						}
					}

					if(k < max(0, j - PRESZ - i))
					{	bool valid = true;
						int x, y;
						for(x = 0; x < i; x++)
						{	for(k = min(j + i + PRESZ, (int)averages[x].size() - 1); k >= max(0, j - PRESZ - x); k--)
							{	////////////
								int lx = min(lvs[k + (x + 1) / 2], (int)thresholds.size() - 1);
								//if(lx < 0) lx = lvs[k] = _getLevels(Lambdas, fplevels, upbound, k+(x+1)/2, (int)tar.size(), t);
								if(averages[x][k] >= thresholds[lx][x])
								////////////
								//if(averages[x][k] >= thresholds[t][x])
								{	if((k > j && _validCover(tar, j, k)) || (k < j && _validCover(tar, k, j)))
									{	valid = false;
										break;
									}
								}
							}
							if(valid == false) break;
						}
						if(valid == true)
						{	vector<double> r;
							r.push_back(j);
							r.push_back(j + i);
							r.push_back(averages[i][j]);
							r.push_back(Lambdas[t]);
							/*for(x = 0; x < (int)result.size(); x++)
							{	if(r[0] <= result[x][0] && r[1] + max(PRESZ, width - 1) >= result[x][0])
									break;
								if(r[0] >= result[x][0] && r[0] <= result[x][1] + max(PRESZ, width - 1))
									break;
							}
							if(x >= (int)result.size())
							*/
								result.push_back(r);

							vector<double> removevalue;
							int rst, red;
//vector<TARRAYRATIO> ttt = dtar;
/*FILE *ff = fopen("tmp.txt", "a");
if(dtar[j].pos == 47488773)
{for(x = max(0, j - 30); x < j + 30 && x < (int)tar.size(); x++)
	fprintf(ff, "%f ", dtar[x].ratio);
fprintf(ff, "\n");
}*/

							declumpPeak(dtar, j, i + 1, removevalue, rst, red);

/*if(dtar[j].pos == 47488773)
{
for(x = max(0, j - 30); x < j + 30 && x < (int)tar.size(); x++)
        fprintf(ff, "%f ", dtar[x].ratio);
fprintf(ff, "\n");
fclose(ff);
//exit(0);
}*/
                                      
/*if(j > 1365800 && j < 1365808) 
{	printf("j=%d rst = %d, red = %d\n", j, rst, red);
	for(x = 0; x < (int)removevalue.size(); x++)
		printf("%f ", removevalue[x]);
	exit(0);	
}*/
/*if((int)result.size() == 10)
{printf("\n%d~%d pos=%d win=%d  real:\t", rst, red, j, i+1);
for(x = rst; x < red; x++) printf("%5.3f ", ttt[x].ratio);
printf("\n%d~%d pos=%d win=%d loess:\t", rst, red, j, i+1);
for(x = 0; x < red - rst; x++) printf("%5.3f ", removevalue[x]);
printf("\n%d~%d pos=%d win=%d   new:\t", rst, red, j, i+1);
for(x = rst; x < red; x++) printf("%5.3f ", dtar[x].ratio);
}*/
							for(x = 0; x < (int)averages.size(); x++)
							{//	printf("\nw%d (%d~%d): ", x + 1, max(0, rst - x), red);
								for(y = max(0, rst - x); y < min(red, (int)averages[x].size()); y++)
								{//	printf("(%5.3f>", averages[x][y]);
									for(k = max(0, y-rst); k <= min(red - rst - 1, y + x - rst); k++)
									{	averages[x][y] -= removevalue[k] / (double)(x + 1);
									}
								//	printf("%5.3f) ", averages[x][y]);
								}
							}
//exit(0);
						}
					}
					//j += i;
				}
			}
		}
		for(i = 0; i < (int)lvs.size(); i++)
		{	//if(t > 0 && lvs[i] >= (int)thresholds.size() - 1) lvs[i] = _getLevels(Lambdas, fplevels, upbound, i, (int)tar.size(), t - 1);
			//else 
			lvs[i]--;
			if(lvs[i] < 0) lvs[i]=0;
		}
	}
}

int _getLevels(vector<double> const &Lambdas, vector<double> const &fplevels, double upbound, int pos, int L, int curlevel)
{
	int k = curlevel;
	if((int)fplevels.size() > 0)
        {       double level = fplevels[pos] * (double)L / upbound * Lambdas[curlevel];
                for(k = 0; k < (int)Lambdas.size(); k++) if(Lambdas[k] <= level) break;                                
		if(k >= (int)Lambdas.size())
		{	if(level <= 0) k = 10000000;
			else k += (int)(log(*(Lambdas.end() - 1) / level) / log(Lambdas[0] / Lambdas[1]));
		}
	}
	return k;
}

void getLambdas(vector<double> const &priors, double totalLambda, double maxBound, vector<double> &lambdas, double &minl, double &maxl)
{
	int i, j;
	lambdas.clear();
	minl = maxl = 0;
	if((int)priors.size() == 0) return;
	
	if(totalLambda > (double)priors.size() * maxBound)
		totalLambda = (double)priors.size() * maxBound;

	lambdas.resize((int)priors.size(), 0);
	double sum = 0;
	for(i = 0; i < (int)priors.size(); i++) 
		sum += priors[i];
	if(sum <= 0 || totalLambda <= 0) return;

	for(i = 0; i < (int)lambdas.size(); i++)
		lambdas[i] = priors[i] / sum * totalLambda;
	
	minl = totalLambda, maxl = 0;
	for(i = 0; i < (int)lambdas.size(); i++)
	{	if(minl > lambdas[i] && lambdas[i] > 0) minl = lambdas[i];
		if(maxl < lambdas[i]) maxl = lambdas[i];
	}

	if(maxl > maxBound)
	{	double scale = (totalLambda * maxl / maxBound - totalLambda) / (maxl * (double)priors.size() - totalLambda);
		if(maxl * (double)priors.size() - totalLambda == 0) scale = 0;
		minl = totalLambda;
		for(i = 0; i < (int)priors.size(); i++)
		{	lambdas[i] = (lambdas[i] + (maxl - lambdas[i]) * scale) * maxBound / maxl;
			if(minl > lambdas[i]) minl = lambdas[i];
		}
		maxl = maxBound;
	}
}

void estimateThresholds_theoretical_joint_withPriors(vector<TARRAYRATIO> const &tar, int wst, int wed, vector<double> const &priors, double totalLambda,
				vector<double> &Lambdas, vector<vector<double> > &thresholds, vector<double> &fplevels, vector<vector<double> > &cov, vector<vector<double> > &cl, int run)
{	int i, j, k;
	Lambdas.clear();
	thresholds.clear();
	//esitmate maxmeans theoretically
	//first, determine a proper range to work with
	double minl, maxl;
	getLambdas(priors, totalLambda, totalLambda, fplevels, minl, maxl);
	if(maxl <= 0) return;

	double omaxl = maxl, upl = maxl, downl = 0;
	vector<double> tryu, tmplambdas(wed, 0);
	int count = 0;
	do
	{	for(i = wst - 1; i < wed; i++)
		{	tmplambdas[i] = maxl * (double)tar.size() / (double)(wed - wst + 1);	}
		estimateThresholds_theoretical2(tar, wst, wed, tmplambdas, tryu, 0, cov, cl, true, run);
		
		for(i = wst - 1; i < wed; i++)
		{	if(tryu[i] < minBound * 0.99) break;
		}

		if(i < wed)
		{	upl = maxl; maxl = (maxl + downl) / 2.;	}
		else if(maxl < omaxl && tryu[wed - 1] > minBound * 1.1)
		{	downl = maxl; maxl = (maxl + upl) / 2.;	}
		count++;
	} while((i < wed || (maxl < omaxl && tryu[wed - 1] > minBound * 1.1)) && count < 20);

	if(maxl < omaxl) getLambdas(priors, totalLambda, maxl, fplevels, minl, maxl);
	
	{	FILE *f = fopen("lambda_priors.txt", "w");
		fprintf(f, "Id\tpiror\tlambda\tTotal # of FP = %f\n", totalLambda);
		for(i = 0; i < (int)fplevels.size(); i++)
			fprintf(f, "%d\t%f\t%f\n", i, priors[i], fplevels[i]);
		fclose(f);
	}

	if(minl * 100. > maxl) minl = maxl / 100.;
	if(minl * (double)tar.size() > 0.05) minl = 0.05 / (double)tar.size();

	double step = log(100.) / 100.;
	int sz = (int)(log(maxl / minl) / step + 0.5) + 1;
	Lambdas.resize(sz);
	for(i = 0; i < Lambdas.size(); i++)
		Lambdas[i] = exp(log(maxl) - (double)i * step) * (double)tar.size(); //ignore the fact that some windows maybe undefined due to uneven tiling
	
	int itern = (int)(((double)sz - 20.) / 81. + 0.9999999);
	vector<double> xlambda;
	vector<vector<double> > yus;
	for(int r = 0; r < itern; r++)
	{	int st = r * 80;
		int ed = min(r * 80 + 100, sz - 1);

		vector<double> startu, endu;
		if(r == 0) startu = tryu;
		else 
		{	for(i = wst - 1; i < wed; i++)
			{	tmplambdas[i] = Lambdas[st] / (double)(wed - wst + 1);	}
			estimateThresholds_theoretical2(tar, wst, wed, tmplambdas, startu, 0, cov, cl, true, run);
		}
		for(i = wst - 1; i < wed; i++)
		{	tmplambdas[i] = Lambdas[ed] / (double)(wed - wst + 1);	}
		estimateThresholds_theoretical2(tar, wst, wed, tmplambdas, endu, 0, cov, cl, true, run);
		
		tmplambdas.resize(ed - st + 1);
		for(i = st; i <= ed; i++)
			tmplambdas[i - st] = Lambdas[i] / (double)(wed - wst + 1);

		vector<vector<double> > us;
		for(i = wst - 1; i < wed; i++)
		{	if(wst > 1)
			{	us.resize(ed - st + 1, vector<double>(wst - 1, 1000000.));
			}
			int presz = PRESZ + i, l;
			vector<double> coverdist, sufdist;
			getCoverDist(tar, i + 1, coverdist, l);
			getSufDist(tar, i + 1, sufdist);
			if((int)coverdist.size() > 0) presz = (int)coverdist.size() - 1;
			int sufsz = max(0, (int)sufdist.size() - 1);

			vector<double> u((int)tmplambdas.size()); //check more points
			vector<vector<double> > estn;
			for(j = 0; j < (int)u.size(); j++)
				u[j] = startu[i] + (endu[i] - startu[i]) * log(tmplambdas[j] / tmplambdas[0]) / log(tmplambdas[ed - st] / tmplambdas[0]);
			printf("Joint winsize = %d, lambda_%d = %5.3f~%5.3f\n", i + 1, i + 1, Lambdas[ed] / (double)(wed - wst + 1), Lambdas[st] / (double)(wed - wst + 1)); fflush(stdout);
			estimateP_maxpeak(u, i + 1, cov, cl, run, coverdist, sufdist, us, estn);
			
			if((int)us.size() == 0)
			{	us.resize(ed - st + 1);
				estn.resize(ed - st + 1);
				for(j = 1; j < ed - st + 1; j++)
					estn[j] = estn[0];
			}
			for(j = 0; j < ed - st + 1; j++)
			{	for(k = 0; k < (int)estn[j].size(); k++)
					if(estn[j][k] * (double)l <= tmplambdas[j])
						break;
				if(k >= (int)estn[j].size())
					us[j].push_back(*(u.end() - 1));
				else if(k == 0) us[j].push_back(*(u.begin()));
				else us[j].push_back(u[k - 1] + log(estn[j][k - 1] * l / tmplambdas[j]) / log(estn[j][k - 1]/estn[j][k]) * (u[k] - u[k - 1]));
			}	
		}
		xlambda.insert(xlambda.end(), Lambdas.begin() + st, Lambdas.begin() + ed + 1);
		yus.insert(yus.end(), us.begin(), us.end());
	}
	vector<MYTYPE> myorder((int)xlambda.size());
	for(i = 0; i < (int)xlambda.size(); i++)
	{	myorder[i].ratio = xlambda[i];
		myorder[i].index = i;
	}
	sort(myorder.begin(), myorder.end());
	
	FILE *f1 = fopen("debug.txt", "w");
	for(i = 0; i < (int)yus.size(); i++)
	{	fprintf(f1, "%f\t", xlambda[i]);
		for(j = wst - 1; j < wed; j++)
			fprintf(f1, "%f\t", yus[i][j]);
		fprintf(f1, "\n");
	}
	fclose(f1);

	vector<double> newx((int)xlambda.size());
	for(i = 0; i < (int)myorder.size(); i++)
		newx[i] = xlambda[myorder[i].index];
	if(wst > 1) thresholds.resize((int)Lambdas.size(), vector<double>(wst - 1, 1000000.));
	else thresholds.resize((int)Lambdas.size());
	double span = min(0.5, 30. / (double)newx.size());

	for(i = wst - 1; i < wed; i++)
	{	vector<double> newy((int)xlambda.size());
		for(j = 0; j < (int)myorder.size(); j++)
			newy[j] = yus[myorder[j].index][i];
		for(j = 0; j < (int)Lambdas.size(); j++)
			thresholds[j].push_back(_loess(newx, newy, Lambdas[j], span, true));
	}
	
	FILE *f = fopen("thresholds_all.txt", "w");
	for(i = 0; i < (int)Lambdas.size(); i++)
	{	fprintf(f, "%f\t", Lambdas[i]);
		for(j = wst - 1; j < wed; j++)
			fprintf(f, "%f\t", thresholds[i][j]);
		fprintf(f, "\n");
	}
	fclose(f);
}

double _loess(vector<double> const &x, vector<double> const &y, double xstar, double span, bool incorder)
{	int i;
	double alpha, beta;
	{	vector<double> nx = x, ny = y;
		if(!incorder)
		{	vector<MYTYPE> order((int)x.size());
			for(i = 0; i < (int)x.size(); i++)
			{	order[i].ratio = x[i];
				order[i].index = i;
			}
			sort(order.begin(), order.end());
			for(i = 0; i < (int)x.size(); i++)
			{	nx[i] = x[order[i].index];
				ny[i] = y[order[i].index];
			}
		}
		return _wlm(nx, ny, xstar, span, alpha, beta);
	}
}

double _wlm(vector<double> const &x, vector<double> const &y, double xstar, double span, double &alpha, double &beta)
{	int i, id;
	int sz = (int)(span / 2. * (double)x.size() + 0.5) + 1;
	
	if(xstar < x[0]) id = 0;
	else if(xstar > *(x.end() - 1)) id = (int)x.size() - 1;
	else 	
	{	for(id = 0; id < (int)x.size() - 1; id++)
			if(x[id] <= xstar && x[id + 1] >= xstar) break;
	}
	int st = max(0, id - sz);
	int ed = min((int)x.size(), id + sz + 1);
	double rt = 0;
	if(ed - st < 2) 
	{	rt = alpha = y[id];
		beta = 0;
		return rt;
	}

	vector<double> w(ed - st, 0);
	double maxd = fabs(xstar - x[ed - 1]);
	if(maxd < fabs(xstar - x[st])) maxd = fabs(xstar - x[st]);
	for(i = st; i < ed; i++)
		w[i - st] = pow(1 - pow(fabs(xstar - x[i]) / maxd, 3.), 1.5);

	double xy, x2, xbar, ybar, wbar;
	xy = x2 = xbar = ybar = wbar = 0;
	for(i = st; i < ed; i++)
	{	xy += x[i] * y[i] * w[i - st];
		x2 += x[i] * x[i] * w[i - st];
		xbar += x[i] * w[i - st];
		ybar += y[i] * w[i - st];
		wbar += w[i - st];
	}
	if(wbar == 0) wbar = 0.0000001;
	if(wbar * x2 - xbar * xbar != 0) 
	{	beta = (wbar * xy - xbar * ybar) / (wbar * x2 - xbar * xbar);
		alpha = (ybar - beta * xbar) / wbar;
		rt = xstar * beta + alpha;
	}
	else rt = (y[0] + *(y.end() - 1)) / 2.;

	return rt;
}
