#
# Python script that takes a folder and a file
# and creates the galaxy html 
#
# @author James Boocock.


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



def create_html(file_dir, html_file, base_name):
    print "1"
    

