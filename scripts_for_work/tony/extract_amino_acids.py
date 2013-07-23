import os
import sys
import re

#
# $1 input_vcf
#

def main():
    f1=sys.argv[1]
    with open(f1,'w') as f:
        for line in f:
            if "#" not in line:
                lineTab = line.split('\t')
                lineEight=lineTab[7]
                lineEight=   
                    
                 


if __name__=="__main__":main()
