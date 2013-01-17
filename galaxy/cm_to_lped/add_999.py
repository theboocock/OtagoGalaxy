#!/bin/env/python

#
#
#
# @author James Boocock
# Simple script to add missing centimorgan value of 999 
#
# $1 file to add 999s
# $2 missng value

import sys

def main():
    u_file=sys.argv[1]
    with open(u_file,'r') as f:
        for line in f:
            
            if (line.split()[0] == "24" or line.split()[0] == "26"):
                print line.split()[0] + ' ' + line.split()[1] +' '+  missing_value + ' ' +  line.split()[3]



if __name__=="__main__":main()
