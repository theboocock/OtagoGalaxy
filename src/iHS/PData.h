#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <vector>
#include <string>
#include <string.h>
#include <stdio.h>
#include "Ehh.h"

using namespace std;

class PData {
  
 public:

  PData(){
    rsize = 2000000;
    gap_psize = 20000;
  }
  
  void load_info(char *infofile);
  int  load_data(char *datafile);  
  void compute_data(int index);
  
  int snp_num;

  vector<string> snp_list;

 private:
  
  vector<char *> data;

  vector<int> phy_map;
  vector<float> gen_map;
  vector<int> sw_list;

  Ehh ehh;
  
  int rsize;
  int gap_psize;
  
};
