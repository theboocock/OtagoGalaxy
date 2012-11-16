#
# Python script that annotates the centimorgans to a map file
#
# $1 GENETIC_MAP FILE
# $2 user_MAP FILE
#
# @author James Boocock
# @date   16/11/2012
#

import os
import sys

def main():
    genetic_map_file=sys.argv[1]
    user_map_file=sys.argv[2]
    with open(user_map_file, 'r') as umap:
        with open(genetic_map_file, 'r') as gmap:
            u_line=umap.readline()
            g_line=gmap.readline()
            while(gmap and umap):
                u_line=u_line.split()
                g_line=g_line.split()
                u_posl=u_line[3]
                g_line=g_line[0]
                if(u_posl == g_pos1):
                    print u_line[0] + ' '+ u_line[1] + ' ' + g_line[2]+ ' ' + u_line[3]
                elif (u_posl < g_pos1):
                    u_line=umap.readline()
                if not u_line: break
                else:
                    g_line=read.line()
                    if not g_line: break
                u_line=umap.readline()
                g_line=gmap.readline()


            

    



if __name__=="__main__":main()
