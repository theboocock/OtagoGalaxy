#include "Ehh.h"

void Ehh::load_data(const std::vector<char *> &data, const std::vector<float> &gen_map, const std::vector<float> &gap_list){
  
  // input data
  whole_data = data;
  gmap = gen_map;
  gapv = gap_list;
  
  //initialize values
  c_rho0=c_rho1=rho0=rho1=-1;
  hap_len0=hap_len1=0;
      
  int_s0 = 0;
  int_s1 = 0;
  
  int_ps0 = 0;
  int_ps1 = 0;

  
  max_ggap = 0;
  
  total_marker=0;
  gap_count=0;
  total_int_dist=0;
  
  compute_ehh();
}
  
void Ehh::compute_ehh(){
  
  // state clean-up

  int n0 = 0;
  int n1 = 0;
  
  ehh0.clear();
  ehh1.clear();
  mhap0.clear();
  mhap1.clear();
  data0.clear();
  data1.clear();
  

  // split data
  for(int i=0;i<whole_data.size();i++){
    char *str = whole_data[i];
    if(str[0] == '0'){
      data0.push_back(str);
      n0++;
    }else if(str[0]=='1'){
      data1.push_back(str);
      n1++;
    }
  }
  if(n0==0 || n1==0||n0==1||n1==1)
    return;

  ehh0.push_back(1);
  ehh1.push_back(1);
  mhap0.push_back(n0);
  mhap1.push_back(n1);
  
  int hap0 =0;
  int hap1 =0;
  for(int i=2;i<=strlen(data0[0]);i++){
    ehh0.push_back(compute_ehh_score(n0,n1,i,data0,hap0));
    if(hap0 >0)
      mhap0.push_back(hap0);
    ehh1.push_back(compute_ehh_score(n1,n0,i,data1,hap1));
    if(hap1>0)
       mhap1.push_back(hap1);
  }
  
    

  if(ehh0.size()<2){
    c_rho0=c_rho1=rho0=rho1=-1;
    return;
  }
    
  // compute T statistic 
  
 float cd0 = 0;
  
  for(int i=0;i<ehh0.size();i++){
    if(ehh0[i]<thresh){
      rho0=fabs(gmap[0]-gmap[i]);
      break;
    }
    if(i!=ehh0.size())
      cd0 += (1-gapv[i])*fabs(gmap[i+1]-gmap[i]);
    
  }
  
  
  float cd1 = 0;
  for(int i=0;i<ehh1.size();i++){
    if(ehh1[i]<thresh){
      rho1=fabs(gmap[0]-gmap[i]);
      break;
    }
    if(i!=ehh1.size())
      cd1 += (1-gapv[i])*fabs(gmap[i+1]-gmap[i]);
  }    
  
  c_rho1 = rho1 - cd1;
  c_rho0 = rho0 - cd0;
  

  
  //longest common hapolotype length in 0 and 1
  // and related integrals
  /*
  for(int i=0;i<mhap0.size()-1;i++){
    float len = gapv[i]*fabs(gmap[i+1]-gmap[i]);
    int_ps0 += len*(float)(mhap0[i]+mhap0[i+1])*.5;
    hap_len0 += len;
  }
  if(int_ps0==0){
    hap_len0 = gapv[0]*fabs(gmap[1]-gmap[0]);
    int_ps0 = hap_len0*mhap0[0]*.5; 
  }
  int_ps0 = int_ps0/n0;

  for(int i=0;i<mhap1.size()-1;i++){
    float len = gapv[i]*fabs(gmap[i+1]-gmap[i]);
    int_ps1 += len*(float)(mhap1[i]+mhap1[i+1])*.5;
    hap_len1 += len;
  }
  
  if(int_ps1==0){
    hap_len1 = gapv[0]*fabs(gmap[1]-gmap[0]);
    int_ps1 = hap_len1*mhap1[0]*.5;
  }
  int_ps1 = int_ps1/n1;
*/
  
  // compute integral
  
  int   count0 = 0;
  int   gcount0=0;
  float td0 = 0;
  float s0 = 0;
  
  int status0 = 1;
 
  for(int i=0;i<ehh0.size()-1;i++){
    
    // gap correction ratio factor
    float ratio =  gapv[i];
    
    if(ratio<1)
      gcount0++;
    
    if(ehh0[i+1]>=0.05){
      
      float step = fabs(gmap[i+1]-gmap[i])*ratio;
      s0+= (ehh0[i]+ehh0[i+1]-0.1)*.5*step;
      count0++;  
      td0 += step;
      if(step>max_ggap)
	max_ggap = step;
    }  
    else{
      status0 = 0;
      if(ehh0[i]<0.05)
	break;
      float dist = ratio*fabs(gmap[i+1]-gmap[i])*(1-(0.05-ehh0[i+1])/(ehh0[i]-ehh0[i+1]));
      s0 += dist*.5*(ehh0[i]-0.05);
      count0++;
      td0+= dist;
      if(dist>max_ggap)
	max_ggap = dist;
      break;
    }
  }

  
  int   count1 = 0;
  int   gcount1 = 0;
  float td1 = 0;
  float s1 = 0;
  
  int status1=1;

  for(int i=0;i<ehh1.size()-1;i++){

    // gap correction ratio factor
    float ratio = gapv[i];
    
    if(ratio<1)
	gcount1++;
    
    
    if(ehh1[i+1]>=0.05){
      float step = fabs(gmap[i+1]-gmap[i])*ratio;
      count1++;
      td1 += step;
      if(step>max_ggap)
	max_ggap = step;
      s1+= (ehh1[i]+ehh1[i+1]-0.1)*.5*step;
    }
    else{
      status1= 0;
      if(ehh1[i]<0.05)
	break;
      count1++;
      float dist = ratio*fabs(gmap[i+1]-gmap[i])*(1-(0.05-ehh1[i+1])/(ehh1[i]-ehh1[i+1]));
      s1 += dist*.5*(ehh1[i]-0.05);
      if(dist>max_ggap)
	max_ggap = dist;
      td1 += dist; 
      break;
    }
  } 
  

  if(status0==1||status1==1)
    status = 1;
  else 
    status = 0;


  if(td1>td0){
    total_int_dist = td1;
    total_marker = count1;
  }else{
    total_int_dist = td0;
    total_marker = count0;
  }
  
  gap_count = gcount0>gcount1 ? gcount0:gcount1; 
    
  int_s0  = s0;
  int_s1  = s1;
  
  //cout<<max_ggap<<"   "<<total_marker<<"    "<<total_int_dist<<endl;
}
    
float Ehh::compute_ehh_score(int n0, int n1, int len, const std::vector<char *> &data, int &hap_max){


  std::map<const char*, int,ltstr> hset;
  std::map<const char* ,int,ltstr>::iterator iter;
   
  float sum = 0;
 
  for(int i=0;i<data.size();i++){ 
    
    char *str = new char[len+1];   
    memset(str,0,len+1);
    memcpy(str, data[i],len);  
    iter = hset.find(str);
    
    //insert a key when necessary
    if ( iter == hset.end())
      hset[str]=1;  
    else{  
      (*iter).second += 1;
      delete[](str);
    }
  }
   

  iter = hset.begin();
  hap_max = 0;
  while(iter!=hset.end()){
    int count = (*iter).second; 
    if( count >= hapcount_thresh&&count>hap_max)
      hap_max = count;
    
    sum+= (float)(*iter).second * (*iter).second;
    delete[]((*iter).first);
    iter++;
  }
  hset.clear();
  
  float ehh = (sum/(n0*n0)-1./n0)/(1-1./n0) + 1./(n0+n1); 
  return ehh;
}
