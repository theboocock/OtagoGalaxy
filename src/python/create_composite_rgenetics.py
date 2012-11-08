#
#Python script to create lped and pbed files
#
# @author James.

import sys
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
    if rg == "lped":
        os.mv(base_name + '.ped', extra_files)
        os.mv(base_name + '.map', extra_files)
    else:
        os.mv(base_name + '.bim', extra_files)
        os.mv(base_name + '.bed', extra_files)
        os.mv(base_name + '.fam', extra_files)
    create_html(extra_files,html_out, base_name)



if __name__:"__main__":main()

