#!/bin/env/python
#
# $1 input basename
# $2 input files path
# $3 input gen file
# $4 output_haps
# $5 output_map
#

import os
import sys
def main():
    basename=sys.argv[1]
    file_path=sys.argv[2]
    in_gen=sys.argv[3]
    out_hap=sys.argv[4]
    out_map=sys.argv[5]
    with open(os.path.join(file_path ,basename + '.map'),'r') as map_file:
        with open(in_gen,'r') as gen_file:
            with open(out_hap, 'w') as hap_file:
                with open(out_map, 'w') as legend_file:
                    line_map=map_file.readline()
                    line_gen=gen_file.readline()
                    list_map=line_map.split()
                    list_gen=line_gen.split()
                    while(line_gen and line_map):
                        legend_file.write(list_map[1]+ ' ' + list_map[3]+ ' '+ list_map[2]+' '+list_gen[3] + ' ' + list_gen[4] + '\n')
                        hap_file.write(' '.join(list_gen[5:]
                        list_map=line_map.split()
                        list_gen=line_gen.split()



if __name__=="__main__":main()
