#include <vector>
#include <cstring>
#include <iostream>
#include <map>
#include <math.h>

struct ltstr
{
  bool operator()(const char* s1, const char* s2) const
  {
    return strcmp(s1, s2) < 0;
  }
};


class Ehh {
  
  
 public:
  
  std::vector<float> ehh0;
  std::vector<float> ehh1;

  std::vector<int>  mhap0;
  std::vector<int>  mhap1;
  
  // statistic computed (interested)

  // uncorrected rho
  float rho0;
  float rho1;  
  

  // corrected rho
  float c_rho0;
  float c_rho1;

  // longest common hapolotype length in 0 and 1
  float hap_len0;
  float hap_len1;
  
  // integral based on hap_len0 and hap_len1
  float int_ps0;
  float int_ps1;
  

  // the integral for 0 and 1
  float int_s0;
  float int_s1;
  
  // gap stats, snp density
  
  float max_ggap;       // maximum gap length in integrated region 
  
  int   total_marker;   // number of markers in integrated region 
  int   gap_count;      // number of gaps over threshold 
  float total_int_dist; // total integrated genetic distance


  
  // status, if ehh score above thresh at the end of the region
  int status;

  
  Ehh(){
    thresh = 0.25;
    hapcount_thresh = 4;
  }
  
  void load_data(const std::vector<char *> &data, const std::vector<float> &map, const std::vector<float> &gap);

  void set_T_thresh(float value){
    thresh = value;
  }

  
 private:
  
  std::vector<char *> whole_data;  
  std::vector<float> gmap;
  std::vector<float>  gapv;  //correction factors for gaps in gmap

  std::vector<char *> data0;
  std::vector<char *> data1;
  
  float thresh;
  int   hapcount_thresh;


  void compute_ehh();
  float compute_ehh_score(int n0,int n1,int len, const std::vector<char *> &data,int &index);

  
};
