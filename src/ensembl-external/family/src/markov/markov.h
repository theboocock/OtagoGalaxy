#define MAX_ID_LENGTH 20
struct hit_struct{
  char protein1[MAX_ID_LENGTH +1];
  char protein2[MAX_ID_LENGTH +1];
  unsigned char evalue1;
  unsigned char evalue2;
};
