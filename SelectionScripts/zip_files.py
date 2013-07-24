import os
import sys
from optparse import OptionParser

#
# @author James Boocock
#
# writes the file to stdout this is the final file.
#

#
# Creates the haps final output file
#
def create_output_haps(folder_list,overlap,r_output)
    i = 1
    for item in folder_list:
        with open(os.path.join(folder_list,r_output),'r') as first_file: 
            for line in first_file:
                if(first_file.split()[2] <= ((window * i) - overlap)):
                    print(line):
                else:
                     i = i + 1

    

def main():
    parser = OptionParser()
    parser.add_option('-f','--folder-list',dest='folder_list',help='File that lists all the folders in order containing all the data needing to be zipper back together.')
    parser.add_option('-o','--overlap',dest='overlap',help='Overlap required to piece the file back together')
    parser.add_option('-r','-results-file',dest='r_output',help='The final file generated from the ihh calculations')
    parser.add_option('-w','--window',dest='window',help='The big window used to generate all the jobs on nesi')
    (options,args) = parser.parse_args()
    create_output_haps(options.folder_list,int(options.overlap),r_output,int(options.window))
    



if __name__=="__main__":main()
