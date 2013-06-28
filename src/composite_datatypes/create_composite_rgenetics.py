#
#Python script to create lped and pbed files
#
# @author James.

import sys
import os
import shutil

""
# $1 rgenetics datatype.
# $2 html_output
# $3 meta_basename for outputfiles
# $4 directory for extra_files.
#
""

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

galhtmlpostfix = """</div>\n</body>\n</html>\n"""

def create_html(file_dir, html_file, base_name, title_page):
    f = file(html_file, 'w')
    f.write(galhtmlprefix)
    f.write("<div>")
    f.write(title_page)
    f.write("</div>")
    flist = os.listdir(file_dir)
    for i, data in enumerate(flist):
        f.write('<li><a href="%s">%s</a></li>\n' % (os.path.split(data)[-1],os.path.split(data)[-1]))
    f.write(galhtmlpostfix)
    f.close()


rgenetics_title="## Rgenetics: http://rgenetics.org Galaxy Tools"
gtool_title="## Gtool data, Otago Galaxy Tools"
shapeit_title="## ShapeIt data, Otago Galaxy Tools"
impute_tite="## Impute data, Otago Galaxy Tools"
ihs_data= "## IHS data, Otago Galaxy Tools"

def main():
    rg = sys.argv[1]
    html_out = sys.argv[2]
    base_name = sys.argv[3]
    extra_files = sys.argv[4]
    try:
        os.mkdir(extra_files)
    except:
        pass
    if rg == "lped":
        title_page=rgenetics_title
        shutil.copy(base_name + '.ped', os.path.join(extra_files, base_name + '.ped'))
        shutil.copy(base_name + '.map', os.path.join(extra_files, base_name + '.map'))
        title_page=rgenetics_title
    elif rg == "tped":
        title_page=rgenetics_title
        shutil.copy(base_name + '.tped', os.path.join(extra_files, base_name + '.tped'))
        shutil.copy(base_name + '.tfam', os.path.join(extra_files, base_name + '.tfam'))
        title_page=rgenetics_title
    elif rg == "pbed":
        title_page=rgenetics_title
        shutil.copy(base_name + '.bim', os.path.join(extra_files, base_name + '.bim'))
        shutil.copy(base_name + '.bed', os.path.join(extra_files, base_name + '.bed'))
        shutil.copy(base_name + '.fam', os.path.join(extra_files, base_name + '.fam'))
        title_page=rgenetics_title
    elif rg == "gtool":
        title_page=gtool_title
        shutil.copy(base_name + '.gen', os.path.join(extra_files, base_name + '.gen'))
        shutil.copy(base_name + '.sample', os.path.join(extra_files, base_name + '.sample'))
    elif rg == "shapeit":
        title_page=shapeit_title
        shutil.copy(base_name + '.haps', os.path.join(extra_files, base_name + '.haps'))
        shutil.copy(base_name + '.sample' , os.path.join(extra_files, base_name + '.sample'))
    elif rg == "impute":
        title_page=impute_tite
        shutil.copy(base_name + '.gen', os.path.join(extra_files, base_name + '.gen'))
        shutil.copy(base_name + '.sample', os.path.join(extra_files, base_name + '.sample'))
    elif rg == "ihs":
        title_page=ihs_title
        shutil.copy(base_name + 'ihshap', os.path.join(extra_files, base_name + '.ihshap'))
        shutil.copy(base_name + 'ihsmap', os.path.join(extra_files, base_name + '.ihsmap'))
    create_html(extra_files,html_out, base_name + '/',title_page)

if __name__=="__main__":main()

