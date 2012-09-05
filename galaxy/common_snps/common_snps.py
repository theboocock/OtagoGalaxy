import sys

# Author James Boocock
# Finds all the snps common to all the files
# and returns a line seperated list
# All filenames are specificed as arguments on the commandline

def snpList(file_name):
    snp_list=[]
    with open(file_name,'r') as f:
        for line in f:
            line =line.split()
            snp_list.append(line[1])
                        
    return snp_list

def get_common_snp_list(snp_total):
    snp_map = {}
    for key in snp_total:
        for rsid in snp_total[key]:
            if rsid in snp_map:
                snp_map[rsid] += 1
            else: 
                snp_map[rsid] = 1
    return snp_map

def __main__():
    file_data = {}
    for file_name in sys.argv:
        if file_name != sys.argv[0]:
            file_data[file_name] = snpList(file_name)
        
    snp_list =get_common_snp_list(file_data)
    for line in snp_list:
        if(snp_list[line] == (len(sys.argv)-1 )):
            print line
    return 0


if __name__=="__main__":__main__()
