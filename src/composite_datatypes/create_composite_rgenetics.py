#
#Python script to create lped and pbed files
#
# @author James.

import sys
import os
import shutil
import html_creation

""
# $1 rgenetics datatype.
# $2 html_output
# $3 meta_basename for outputfiles
# $4 directory for extra_files.
#
""

def main():
    rg = sys.argv[1]
    html_out = sys.argv[2]
    base_name = sys.argv[3]
    extra_files = sys.argv[4]
    try:
        os.mkdir(extra_files)
    except:
        pass
    print os.path.join(extra_files, base_name + '.ped')
    if rg == "lped":
        shutil.move(base_name + '.ped', os.path.join(extra_files, base_name + '.ped'))
        shutil.move(base_name + '.map', os.path.join(extra_files, base_name + '.map'))
    elif rg == "tped":
        shutil.move(base_name + '.tped', os.path.join(extra_files, base_name + '.tped'))
        shutil.move(base_name + '.tfam', os.path.join(extra_files, base_name + '.tfam'))
    elif rg == "pbed":
        shutil.move(base_name + '.bim', os.path.join(extra_files, base_name + '.bim'))
        shutil.move(base_name + '.bed', os.path.join(extra_files, base_name + '.bed'))
        shutil.move(base_name + '.fam', os.path.join(extra_files, base_name + '.fam'))
    html_creation.create_html(extra_files,html_out, base_name + '/')



if __name__=="__main__":main()

