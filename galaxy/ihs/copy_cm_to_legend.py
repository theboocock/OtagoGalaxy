import sys
import os

#
# Annotate CM to ped.
# Copies the cm value from a hapmap recombination file
# to the ped file. 
# 
#
# usage python copy_cm_to_legend.py hapmap_file <  legend file
#
# @author James Boocock
#
#

def main():
    with open(sys.argv[1],'r') as f:
        legend = sys.stdin.readline().split()
        lp = legend[1]
        for line in f:
            line=line.split()
            position=line[1]
            while lp < position:
                legend = sys.stdin.readline().split()
                if not legend:
                    break
                lp = legend[1]
            if lp == position:
                print ' '.join(map(str,legend)) +" " + line[4]  
                legend = sys.stdin.readline().split()
                if not legend:
                    break
                lp = legend[1]


if __name__=="__main__":main()
