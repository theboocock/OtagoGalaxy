#include "PData.h"

int PData::load_data(char *datafile){
  
  
  FILE *fp = fopen(datafile,"r");
  if(fp==0)
    return -1;
    
  vector<char> line;
  
  while(1){
    char in = fgetc(fp); 
    if(isalnum(in)){
      line.push_back(in);
      continue;
    }
    if(in=='\n'||in=='\r'||in==EOF){   
      // convert line to single char array
      if(line.size()>0){
	char *pl = new char[line.size()+1];
	memset(pl,0,line.size()+1);
	for(int i=0;i<line.size();i++){
	  pl[i]=line[i];	  
	}
	data.push_back(pl);	
      }
      line.clear();
    }

    if(in==EOF)
      break;
  }
  
  if(data.size()<1)
    return -2;

  
  snp_num = strlen(data[0]);
  
  return 1;
  
}


void PData::load_info(char *infofile){
  
  FILE *fp = fopen(infofile,"r");
  if(fp==0)
    return;
  char line[128];


  while(fgets(line,128,fp)){
    
   
    char *str = strtok(line," ");
    string marker(str);
  
    snp_list.push_back(marker);
    
    str = strtok(NULL," ");
    phy_map.push_back(atoi(str));
    
    str = strtok(NULL," ");
    gen_map.push_back(atof(str));
    
    str = strtok(NULL," ");
    char c0[3];
    strcpy(c0,str);
    
    str = strtok(NULL," ");
    if(str[strlen(str)-1]=='\n')
      str[strlen(str)-1]=0;
    
    if(strcmp(c0,str)==0)
      sw_list.push_back(0);
    else if(strcmp(str,"NA")==0||strcmp(str,"?")==0)
      sw_list.push_back(-1);
    else
      sw_list.push_back(1);
    
  }
  fclose(fp);
      
}

void PData::compute_data(int index){


  
  if(sw_list[index]==-1)
    return;

  int ipos = phy_map[index];
  int lpos = ipos-rsize;
  int rpos = ipos+rsize;
  
  int lbound = -1;
  int rbound = -1;
  
  for(int i=0;i<phy_map.size();i++){
    if(lbound==-1 && phy_map[i]>=lpos)
      lbound=i;
    if(rbound==-1&& phy_map[i]>rpos){
      rbound=i-1;
      break;
    }
  }
  
  if(rbound==-1)
    rbound = phy_map.size()-1;
  
  

  if(index-lbound+1<5 || rbound-index+1<5)
    return;
 
  
  
  //get left data
  vector<char *> left_data;
  vector<float>  left_gmap;
  vector<float> lgap;
  float freq = 0;
  
  for(int i=0;i<data.size();i++){
    int len = index-lbound+2;
    char *ldata = new char[len];
    memset(ldata,0,len);
    
    if(sw_list[index]==1){
      if(data[i][index]=='0')
	ldata[0]='1';
      else
	ldata[0]='0';
    }else
      ldata[0]=data[i][index];
      
    
    if(ldata[0]=='0')
       freq++;

    int count=1;
    for(int j=index-1;j>=lbound;j--){
      
      // check for gap
      if(i==0){
	float gaps = phy_map[j+1]-phy_map[j];
	if( gaps >gap_psize){
	  
	  if(gaps > 3*gap_psize)
	    lgap.push_back(0);
	  else
	    lgap.push_back((float)gap_psize/gaps);
	}	
	else 
	  lgap.push_back(1);
      }
      
      ldata[count++]=data[i][j];

    }
    
    left_data.push_back(ldata);
  }
  
  for(int i=index;i>=lbound;i--)
    left_gmap.push_back(gen_map[i]);
  
  freq = freq/double(data.size());
  
  if(freq<=0.05||freq>=0.95){
    
    //clean up left_data
    left_gmap.clear();
    lgap.clear();
    for(int i=0;i<left_data.size();i++)
      delete[](left_data[i]);
    left_data.clear();
    return;
  }

  
  //computation is done here
  ehh.load_data(left_data,left_gmap,lgap);

  
  // get results
  float l0 = ehh.rho0;
  float l1 = ehh.rho1;
  
  float cl0 = ehh.c_rho0;
  float cl1 = ehh.c_rho1;
  
  float hap_l0 = ehh.hap_len0;
  float hap_l1 = ehh.hap_len1;
  
  float int_ps0 = ehh.int_ps0;
  float int_ps1 = ehh.int_ps1;
  
  float int_s0 =  ehh.int_s0;
  float int_s1 =  ehh.int_s1;
  
  float max_ggap = ehh.max_ggap;
  
  int   gap_count = ehh.gap_count;
  int   total_marker = ehh.total_marker;
  float total_int_dist = ehh.total_int_dist;
  
  int   status1 = ehh.status;
  

  //clean up left_data
  left_gmap.clear();
  lgap.clear();
  for(int i=0;i<left_data.size();i++)
    delete[](left_data[i]);
  left_data.clear();
  
  if(l0==-1|| l1==-1)
    return;
  
  //get right data
  vector<char *> right_data;
  vector<float>  right_gmap;
  vector<float>    rgap;
  for(int i=0;i<data.size();i++){
  
    char *rdata = new char[rbound-index+2];
    memset(rdata,0,rbound-index+2);
        
    if(sw_list[index]==1){
      if(data[i][index]=='0')
	rdata[0]='1';
      else
	rdata[0]='0'; 
    }else{
      rdata[0]=data[i][index];
    }
        
    int count=1;
    for(int j=index+1;j<=rbound;j++){
      // check for gap
      if(i==0){
	float gaps = phy_map[j]-phy_map[j-1];
	if(gaps>gap_psize){
	  if(gaps>3*gap_psize)
	    rgap.push_back(0);
	  else
	    rgap.push_back((float)gap_psize/gaps);
	}
	else
	  rgap.push_back(1);
      }
      rdata[count++]=data[i][j];
    }
    
        
    right_data.push_back(rdata);
  }
  
  for(int i=index;i<=rbound;i++)
    right_gmap.push_back(gen_map[i]);
   
  
 

  //computation is done here
  ehh.load_data(right_data,right_gmap,rgap);

  
  // get results
  float r0 = ehh.rho0;
  float r1 = ehh.rho1;
  
  float cr0 = ehh.c_rho0;
  float cr1 = ehh.c_rho1;
  
  hap_l0 += ehh.hap_len0;
  hap_l1 += ehh.hap_len1;
  
  int_ps0 += ehh.int_ps0;
  int_ps1 += ehh.int_ps1;
  
  int_s0 +=  ehh.int_s0;
  int_s1 +=  ehh.int_s1;
  

  int status2 = ehh.status;
  

  if(ehh.max_ggap > max_ggap)
    max_ggap = ehh.max_ggap;
    
  gap_count += ehh.gap_count;
  total_marker += ehh.total_marker;
  total_int_dist += ehh.total_int_dist;
  
  
 
  //clean up right_data
  right_gmap.clear();
  for(int i=0;i<right_data.size();i++)
    delete[](right_data[i]);
  right_data.clear();
  
  if(r0==-1|| r1==-1)
    return;
  
  
  //printf("%11s %10d %.3f   %7.3f    %7.2f %7.2f %7.2f %7.3f   %7.2f %7.2f %7.2f %7.3f   %5.2f %5.2f %d\n",snp_list[index].c_str(),phy_map[index],freq, log((cr0+cl0)/(cr1+cl1)),int_s0,int_s1,int_s0-int_s1,log(int_s0/int_s1),int_ps0,int_ps1,int_ps0-int_ps1,log(int_ps0/int_ps1),total_marker/total_int_dist,max_ggap,gap_count);  
  printf("%11s %10d %.3f    %7.2f %7.2f  %7.3f    %5.2f %5.2f %d   %d\n",snp_list[index].c_str(),phy_map[index],freq,int_s0,int_s1,log(int_s0/int_s1),total_marker/total_int_dist,max_ggap,gap_count,status1|status2);  
  
}
  
  




int main(int argc, char **argv){
  
  PData pd;
  
  pd.load_info(argv[1]);
  pd.load_data(argv[2]);
  for(int i=0;i<pd.snp_num;i++) 
    pd.compute_data(i);
  

}
