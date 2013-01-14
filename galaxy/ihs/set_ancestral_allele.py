#
# Set the AA from the 1000 genomes release data
# 
# @author James Boocock
#
# $1 1000 genomes subset vcf
# $2 legend file

import os
import sys
import re

def main():
    vcf_file =sys.argv[1]
    legend_file = sys.argv[2]
    legend =open(legend_file,'r') 
    if not legend_file:
        return 1
    leg_line=legend.readline().split()
    leg_p=leg_line[1]
    with open(vcf_file, 'r') as vcf:
        for line in vcf:
            if not re.match('^#',line):
                line=line.split()
                position=line[1]
                while leg_p < position:
                    leg_line=legend.readline().split()
                    if not leg_line:
                        break
                    leg_p=leg_line[1]
                if leg_p==position:
                    #print the line and annotate the correct ancestral allele
                    #check nacestral allele                    
                    leg_line=legend.readline().split()
                    if not leg_line:
                        break
                    leg_p=leg_line[1]
                    


if __name__=="__main__":main()
