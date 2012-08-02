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
#

java -jar /home/galaxy/galaxy-dist/tool-data/shared/jars/haploview/Haploview.jar -n -ldcolorscheme RSQ -ldvalues RSQ -png -hapmap $1

FILE_NAME=`echo $1 | awk -F[\/] '{print $NF}'`

echo "<html>
<head>
</head>
<body>
<h1> 
Your HapMap LD Plot
</h1>

<img src= '/haploview/images/${FILE_NAME}.LD.PNG'>

</body>
</html>" > $2

exit 0
