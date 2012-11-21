#
# Python script that annotates the centimorgans to a map file
#
# $1 GENETIC_MAP FILE
# $2 user_MAP FILE
# $3 chrom
# 
# Annotates genetic map positions from chromosome based cm files in the hapmap3/impute format
# @author James Boocock
# @date   16/11/2012
#

import os
import sys

def main():
    # hapmap genetic file
    genetic_map_file=sys.argv[1]
    # user map file
    user_map_file=sys.argv[2]
    count = 0
    if (sys.argv[3] == 'X_PAR2'):
        sys.argv[3] = '23'
    with open(user_map_file, 'r') as umap:
        with open(genetic_map_file, 'r') as gmap:
            u_line_temp=umap.readline()
            g_line_temp=gmap.readline()
            if (g_line_temp.split()[0] == "position"):
                g_line_temp=gmap.readline()
            while(g_line_temp and u_line_temp):
                u_line=u_line_temp.split()
                g_line=g_line_temp.split()
                u_pos1=u_line[3]
                g_pos1=g_line[0]
                if (u_line[0] == sys.argv[3]):
                    if(long(u_pos1) == long(g_pos1)):
                        print u_line[0] + '\t'+ u_line[1] + '\t' + g_line[2]+ '\t' + u_line[3]
                        u_line_temp=umap.readline()
                        g_line_temp=gmap.readline()
                    elif (long(u_pos1) < long(g_pos1)):
                        print u_line[0] + '\t' + u_line[1]+ '\t' + '-9' + '\t' + u_line[3]
                        u_line_temp=umap.readline()
                    else:
                        g_line_temp=gmap.readline()
                else:
                    u_line_temp=umap.readline()
                count=count + 1
            while(u_line_temp):
                u_line=u_line_temp.split()
                if (u_line[0] == sys.argv[3]):
                    print u_line[0] + '\t' + u_line[1]+ '\t' + '-9' + '\t' + u_line[3]
                u_line_temp=umap.readline()



if __name__=="__main__":main()
