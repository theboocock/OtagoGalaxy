#!/bin/bash
#
# Author: Ed Hills
# Date : 24/1/12
#
# This script will run the HaploView.jar LD Plotter and create an HTML
# page that will embed the output png image.
#
# Inputs
# $1 = input_hapmap
# $2 = html_output

java -jar /home/galaxy/galaxy-dist/tool-data/shared/jars/haploview/HaploView.jar -n -ldcolorscheme RSQ -ldvalues RSQ -png -hapmap $1

echo "
<html>
<head>
</head>
<body>
<img src= '/home/galaxy/galaxy-dist/database/files/000/${1}.LD.PNG'>
</body>
</html>
" > $2
