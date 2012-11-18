#
# Python script that annotates the centimorgans to a map file
#
# $1 GENETIC_MAP FILE
# $2 user_MAP FILE
# $3 chrom
#
# @author James Boocock
# @date   16/11/2012
#

import os
import sys

def main():
    genetic_map_file=sys.argv[1]
    user_map_file=sys.argv[2]
    if (sys.argv[3] == 'X'):
        sys.arv[3] = '24'
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
                        print "WIN2 " +  u_line[0] + ' '+ u_line[1] + ' ' + g_line[2]+ ' ' + u_line[3]
                        u_line_temp=umap.readline()
                        g_line_temp=gmap.readline()
                    elif (long(u_pos1) < long(g_pos1)):
                        u_line_temp=umap.readline()
                    else:
                        g_line_temp=gmap.readline()
                else:
                    u_line_temp=umap.readline()

            

    



if __name__=="__main__":main()
