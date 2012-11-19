#!/bin/env/python
#
# Removes snps from lped file that are missing the cM column
#
# $1 basename
# $2 extra files path
# $3 missing snp code
#
# @author James Boocock
#

import sys
import os
def main():
    basename=sys.argv[1]
    extra_file=sys.argv[2]
    missing_code=sys.argv[3]
    with open(os.path.join(extra_file, basename +'.map'), 'r') as f:
        for line in f:
            if line.split()[2] != missing_code:
                print line.split()[1] 
   



if __name__=="__main__":main()
