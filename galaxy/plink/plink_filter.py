"""
#
# This python script performs the plink filtering determining on a
# ped/map files.
#
# @author James Boocock
#
"""
import sys
"""
$1 input path
$2 input name
$3 hwe filtering option
$4 minor allele frequency filtering option
$5 missing per person 
$6 missing per marker
$7 max maf
$8 mendel error filtering
$9 output path
"""

galhtmlprefix = """<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="generator" content="Galaxy %s tool output - see http://g2.trac.bx.psu.edu/" />
<title></title>
<link rel="stylesheet" href="/static/style/base.css" type="text/css" />
</head>
<body>
<div class="document">
"""
galhtmlattr = """<h3><a href="http://rgenetics.org">Rgenetics</a> tool %s run at %s</h3>"""
galhtmlpostfix = """</div></body></html>\n"""

def run_filter(file_name, output_fname, output_path,inname,hwe,maf,mi_pp, mi_mark, mendel, max_maf):
     outpath = os.path.join(output_path,inname)
     cl = "plink --noweb --file %s --"
     #run command

def main():
    if len(sys.argv) < 10:
        print >> sys.stdout, '## %sexpected 9 params for sys.argv, got %d - %s' % (prog,len(sys.argv),sys.argv)
        sys.exit(1)
    plog = [ '## Plink HWE started %s\n' % timenow ]
    inpath=sys.argv[1]
    inname=sys.argv[2]
    hwe=sys.argv[3]
    maf=sys.argv[4]
    mi_pp=sys.argv[5]
    mi_mark=sys.argv[6]
    max_maf=sys.argv[7]
    mendel=sys.argv[8]
    output_path=sys.argv[9]
    output_fname=sys.argv[10]  
    outputf = os.path.join(output_path, output_fname)
    try:
        os.makedirs(output_path)
    except:
        pass
    file_name = os.path.join(inpath,inname)
    outf = file(output_fname, 'w')
    outf.write(galhtmlprefix % prog)
    run_filter(file_name,output_fname,output_path,inname,hwe,maf,mi_pp,mi_mark,mendel,max_maf)

if __name__:"__main__":main()
